package main

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha1"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"song-recognition/db"
	"song-recognition/models"
	"song-recognition/shazam"
	"song-recognition/spotify"
	"song-recognition/utils"
	"song-recognition/wav"
	"strconv"
	"strings"
	"time"

	socketio "github.com/googollee/go-socket.io"
	"github.com/mdobak/go-xerrors"
)

func downloadStatus(statusType, message string) string {
	data := map[string]interface{}{"type": statusType, "message": message}
	jsonData, err := json.Marshal(data)
	if err != nil {
		logger := utils.GetLogger()
		ctx := context.Background()
		err := xerrors.New(err)
		logger.ErrorContext(ctx, "failed to marshal data.", slog.Any("error", err))
		return ""
	}
	return string(jsonData)
}

func handleTotalSongs(socket socketio.Conn) {
	logger := utils.GetLogger()
	ctx := context.Background()
	print("handleTotalSongs called\n")
	db, err := db.NewDBClient()
	if err != nil {
		err := xerrors.New(err)
		logger.ErrorContext(ctx, "error connecting to DB", slog.Any("error", err))
		return
	}
	defer db.Close()

	totalSongs, err := db.TotalSongs()
	if err != nil {
		err := xerrors.New(err)
		logger.ErrorContext(ctx, "Log error getting total songs", slog.Any("error", err))
		return
	}

	socket.Emit("totalSongs", totalSongs)
}

func handleSongDownload(socket socketio.Conn, spotifyURL string) {
	logger := utils.GetLogger()
	ctx := context.Background()
	logger.Info("handleSongDownload called", slog.String("spotifyURL", spotifyURL))
	// Handle album download
	if strings.Contains(spotifyURL, "album") {
		tracksInAlbum, err := spotify.AlbumInfo(spotifyURL)
		if err != nil {
			fmt.Println("log error: ", err)
			if len(err.Error()) <= 25 {
				socket.Emit("downloadStatus", downloadStatus("error", err.Error()))
				logger.Info(err.Error())
			} else {
				err := xerrors.New(err)
				logger.ErrorContext(ctx, "error getting album info", slog.Any("error", err))
			}
			return
		}

		statusMsg := fmt.Sprintf("%v songs found in album.", len(tracksInAlbum))
		socket.Emit("downloadStatus", downloadStatus("info", statusMsg))

		totalTracksDownloaded, err := spotify.DlAlbum(spotifyURL, SONGS_DIR)
		if err != nil {
			socket.Emit("downloadStatus", downloadStatus("error", "Couldn't to download album."))

			err := xerrors.New(err)
			logger.ErrorContext(ctx, "failed to download album.", slog.Any("error", err))
			return
		}

		statusMsg = fmt.Sprintf("%d songs downloaded from album", totalTracksDownloaded)
		socket.Emit("downloadStatus", downloadStatus("success", statusMsg))
	}

	// Handle playlist download
	if strings.Contains(spotifyURL, "playlist") {
		tracksInPL, err := spotify.PlaylistInfo(spotifyURL)
		if err != nil {
			if len(err.Error()) <= 25 {
				socket.Emit("downloadStatus", downloadStatus("error", err.Error()))
				logger.Info(err.Error())
			} else {
				err := xerrors.New(err)
				logger.ErrorContext(ctx, "error getting album info", slog.Any("error", err))
			}
			return
		}

		statusMsg := fmt.Sprintf("%v songs found in playlist.", len(tracksInPL))
		socket.Emit("downloadStatus", downloadStatus("info", statusMsg))

		totalTracksDownloaded, err := spotify.DlPlaylist(spotifyURL, SONGS_DIR)
		if err != nil {
			socket.Emit("downloadStatus", downloadStatus("error", "Couldn't download playlist."))

			err := xerrors.New(err)
			logger.ErrorContext(ctx, "failed to download playlist.", slog.Any("error", err))
			return
		}

		statusMsg = fmt.Sprintf("%d songs downloaded from playlist.", totalTracksDownloaded)
		socket.Emit("downloadStatus", downloadStatus("success", statusMsg))
	}

	// Handle track download
	if strings.Contains(spotifyURL, "track") {
		trackInfo, err := spotify.TrackInfo(spotifyURL)
		if err != nil {
			if len(err.Error()) <= 25 {
				socket.Emit("downloadStatus", downloadStatus("error", err.Error()))
				logger.Info(err.Error())
			} else {
				err := xerrors.New(err)
				logger.ErrorContext(ctx, "error getting album info", slog.Any("error", err))
			}
			return
		}

		// check if track already exist
		db, err := db.NewDBClient()
		if err != nil {
			fmt.Errorf("Log - error connecting to DB: %d", err)
		}
		defer db.Close()

		song, songExists, err := db.GetSongByKey(utils.GenerateSongKey(trackInfo.Title, trackInfo.Artist))
		if err == nil {
			if songExists {
				statusMsg := fmt.Sprintf(
					"'%s' by '%s' already exists in the database (https://www.youtube.com/watch?v=%s)",
					song.Title, song.Artist, song.YouTubeID)

				socket.Emit("downloadStatus", downloadStatus("error", statusMsg))
				return
			}
		} else {
			err := xerrors.New(err)
			logger.ErrorContext(ctx, "failed to get song by key.", slog.Any("error", err))
		}

		totalDownloads, err := spotify.DlSingleTrack(spotifyURL, SONGS_DIR)
		if err != nil {
			if len(err.Error()) <= 25 {
				socket.Emit("downloadStatus", downloadStatus("error", err.Error()))
				logger.Info(err.Error())
			} else {
				err := xerrors.New(err)
				logger.ErrorContext(ctx, "error getting album info", slog.Any("error", err))
			}
			return
		}

		statusMsg := ""
		if totalDownloads != 1 {
			statusMsg = fmt.Sprintf("'%s' by '%s' failed to download", trackInfo.Title, trackInfo.Artist)
			socket.Emit("downloadStatus", downloadStatus("error", statusMsg))
		} else {
			statusMsg = fmt.Sprintf("'%s' by '%s' was downloaded", trackInfo.Title, trackInfo.Artist)
			socket.Emit("downloadStatus", downloadStatus("success", statusMsg))
		}
	}
}

// handleNewRecording saves new recorded audio snippet to a WAV file.
// func handleNewRecording(socket socketio.Conn, recordData string) {
// 	logger := utils.GetLogger()
// 	ctx := context.Background()
// 	print("handleNewRecording called\n")
// 	var recData models.RecordData
// 	if err := json.Unmarshal([]byte(recordData), &recData); err != nil {
// 		err := xerrors.New(err)
// 		logger.ErrorContext(ctx, "Failed to unmarshal record data.", slog.Any("error", err))
// 		return
// 	}

// 	err := utils.CreateFolder("recordings")
// 	if err != nil {
// 		err := xerrors.New(err)
// 		logger.ErrorContext(ctx, "Failed create folder.", slog.Any("error", err))
// 	}

// 	now := time.Now()
// 	fileName := fmt.Sprintf("%04d_%02d_%02d_%02d_%02d_%02d.wav",
// 		now.Second(), now.Minute(), now.Hour(),
// 		now.Day(), now.Month(), now.Year(),
// 	)
// 	filePath := "recordings/" + fileName

// 	decodedAudioData, err := base64.StdEncoding.DecodeString(recData.Audio)
// 	if err != nil {
// 		err := xerrors.New(err)
// 		logger.ErrorContext(ctx, "Failed to decode base64", slog.Any("error", err))
// 	}

// 	err = wav.WriteWavFile(filePath, decodedAudioData, recData.SampleRate, recData.Channels, recData.SampleSize)
// 	if err != nil {
// 		err := xerrors.New(err)
// 		logger.ErrorContext(ctx, "Failed write wav file.", slog.Any("error", err))
// 	}
// 	matches,_:= find2(filePath)
// 	jsonData, err := json.Marshal(matches)

// 	if len(matches) > 10 {
// 		jsonData, _ = json.Marshal(matches[:10])
// 	}

// 	if err != nil {
// 		err := xerrors.New(err)
// 		logger.ErrorContext(ctx, "failed to marshal matches.", slog.Any("error", err))
// 		return
// 	}

// 	socket.Emit("matches", string(jsonData))
// }

func handleNewRecording(socket socketio.Conn, recordData string) {
	logger := utils.GetLogger()
	ctx := context.Background()
	print("handleNewRecording called\n")
	var recData models.RecordData
	if err := json.Unmarshal([]byte(recordData), &recData); err != nil {
		err := xerrors.New(err)
		logger.ErrorContext(ctx, "Failed to unmarshal record data.", slog.Any("error", err))
		return
	}

	err := utils.CreateFolder("recordings")
	if err != nil {
		err := xerrors.New(err)
		logger.ErrorContext(ctx, "Failed create folder.", slog.Any("error", err))
	}

	now := time.Now()
	fileName := fmt.Sprintf("%04d_%02d_%02d_%02d_%02d_%02d.wav",
		now.Second(), now.Minute(), now.Hour(),
		now.Day(), now.Month(), now.Year(),
	)
	filePath := "recordings/" + fileName

	decodedAudioData, err := base64.StdEncoding.DecodeString(recData.Audio)
	if err != nil {
		err := xerrors.New(err)
		logger.ErrorContext(ctx, "Failed to decode base64", slog.Any("error", err))
	}

	err = wav.WriteWavFile(filePath, decodedAudioData, recData.SampleRate, recData.Channels, recData.SampleSize)
	if err != nil {
		err := xerrors.New(err)
		logger.ErrorContext(ctx, "Failed write wav file.", slog.Any("error", err))
	}
	// matches,_:= find2(filePath)
	// jsonData, err := json.Marshal(matches)

	// if len(matches) > 10 {
	// 	jsonData, _ = json.Marshal(matches[:10])
	// }

	// if err != nil {
	// 	err := xerrors.New(err)
	// 	logger.ErrorContext(ctx, "failed to marshal matches.", slog.Any("error", err))
	// 	return
	// }
	response, err := IdentifyAudio(filePath)
	fmt.Printf("%v\n", response)
	if err != nil {
		err := xerrors.New(err)
		logger.ErrorContext(ctx, "cant get response.", slog.Any("error", err))
	}
	// Parse response JSON
	var parsed map[string]interface{}
	if err := json.Unmarshal([]byte(response), &parsed); err != nil {
		logger.ErrorContext(ctx, "Failed to parse response JSON.", slog.Any("error", err))
		return
	}

	// Extract Spotify track ID
	var spotifyURL string
	if metadata, ok := parsed["metadata"].(map[string]interface{}); ok {
		if musicList, ok := metadata["music"].([]interface{}); ok && len(musicList) > 0 {
			firstTrack := musicList[0].(map[string]interface{})
			if extMeta, ok := firstTrack["external_metadata"].(map[string]interface{}); ok {
				if spotify, ok := extMeta["spotify"].(map[string]interface{}); ok {
					if track, ok := spotify["track"].(map[string]interface{}); ok {
						if trackID, ok := track["id"].(string); ok {
							spotifyURL = "https://open.spotify.com/track/" + trackID
						}
					}
				}
			}
		}
	}
	trackInfo, err := spotify.TrackInfo(spotifyURL)
	fmt.Println("Track info: ", trackInfo)
	fmt.Println(spotifyURL)
	if err != nil {
		if len(err.Error()) <= 25 {
			socket.Emit("downloadStatus", downloadStatus("error", err.Error()))
			logger.Info(err.Error())
		} else {
			err := xerrors.New(err)
			logger.ErrorContext(ctx, "error getting album info", slog.Any("error", err))
		}
		return
	}

	// check if track already exist
	db, err := db.NewDBClient()
	if err != nil {
		fmt.Errorf("Log - error connecting to DB: %d", err)
	}
	defer db.Close()
	totalDownloads, err := spotify.DlSingleTrack(spotifyURL, SONGS_DIR)
	if err != nil {
		if len(err.Error()) <= 25 {
			socket.Emit("downloadStatus", downloadStatus("error", err.Error()))
			logger.Info(err.Error())
		} else {
			err := xerrors.New(err)
			logger.ErrorContext(ctx, "error getting album info", slog.Any("error", err))
		}
		return
	}

	statusMsg := ""
	if totalDownloads != 1 {
		statusMsg = fmt.Sprintf("'%s' by '%s' failed to download", trackInfo.Title, trackInfo.Artist)
		socket.Emit("downloadStatus", downloadStatus("error", statusMsg))
	} else {
		statusMsg = fmt.Sprintf("'%s' by '%s' was downloaded", trackInfo.Title, trackInfo.Artist)
		socket.Emit("downloadStatus", downloadStatus("success", statusMsg))
	}

	song, _, err := db.GetSongByKey(utils.GenerateSongKey(trackInfo.Title, trackInfo.Artist))
	print("Song key: " + utils.GenerateSongKey(trackInfo.Title, trackInfo.Artist) + "\n" + song.YouTubeID)
	fmt.Print("Song YouTube ID: " + song.YouTubeID + "\n")
	socket.Emit("matches", song.YouTubeID)
	if err == nil {

		socket.Emit("downloadStatus", downloadStatus("info", "You have searched this earlier!"))
		return

	} else {
		err := xerrors.New(err)
		logger.ErrorContext(ctx, "failed to get song by key.", slog.Any("error", err))
	}

	// totalDownloads, err := spotify.DlSingleTrack(spotifyURL, SONGS_DIR)
	// if err != nil {
	// 	if len(err.Error()) <= 25 {
	// 		socket.Emit("downloadStatus", downloadStatus("error", err.Error()))
	// 		logger.Info(err.Error())
	// 	} else {
	// 		err := xerrors.New(err)
	// 		logger.ErrorContext(ctx, "error getting album info", slog.Any("error", err))
	// 	}
	// 	return
	// }

	// statusMsg := ""
	// if totalDownloads != 1 {
	// 	statusMsg = fmt.Sprintf("'%s' by '%s' failed to download", trackInfo.Title, trackInfo.Artist)
	// 	socket.Emit("downloadStatus", downloadStatus("error", statusMsg))
	// } else {
	// 	statusMsg = fmt.Sprintf("'%s' by '%s' was downloaded", trackInfo.Title, trackInfo.Artist)
	// 	socket.Emit("downloadStatus", downloadStatus("success", statusMsg))
	// }
	fmt.Println(song.YouTubeID)

}

func handleNewFingerprint(socket socketio.Conn, fingerprintData string) {
	logger := utils.GetLogger()
	ctx := context.Background()
	print("handleNewFingerprint called\n" + fingerprintData + "\n")
	var data struct {
		Fingerprint map[uint32]uint32 `json:"fingerprint"`
	}
	if err := json.Unmarshal([]byte(fingerprintData), &data); err != nil {
		err := xerrors.New(err)
		logger.ErrorContext(ctx, "Failed to unmarshal fingerprint data.", slog.Any("error", err))
		return
	}

	matches, _, err := shazam.FindMatchesFGP(data.Fingerprint)
	if err != nil {
		err := xerrors.New(err)
		logger.ErrorContext(ctx, "failed to get matches.", slog.Any("error", err))
	}

	jsonData, err := json.Marshal(matches)
	if len(matches) > 10 {
		jsonData, _ = json.Marshal(matches[:10])
	}

	if err != nil {
		err := xerrors.New(err)
		logger.ErrorContext(ctx, "failed to marshal matches.", slog.Any("error", err))
		return
	}

	socket.Emit("matches", string(jsonData))
}

func handleAllYouTubeIDs(socket socketio.Conn) {
	logger := utils.GetLogger()
	ctx := context.Background()

	dbClient, err := db.NewDBClient()
	if err != nil {
		err := xerrors.New(err)
		logger.ErrorContext(ctx, "error connecting to DB", slog.Any("error", err))
		return
	}
	defer dbClient.Close()

	ytIDs, err := dbClient.GetAllYouTubeIDs()
	if err != nil {
		err := xerrors.New(err)
		logger.ErrorContext(ctx, "error getting YouTube IDs", slog.Any("error", err))
		return
	}

	socket.Emit("allYouTubeIDs", ytIDs)
}

func IdentifyAudio(filePath string) (string, error) {
	// Replace with your credentials and host
	accessKey := "c8f2960b4681811a62e846effcc2301a"
	accessSecret := "F5XaHKnJphY070mYVdqmKSjr7GxFgS3BX559lhIA"
	reqURL := "https://identify-ap-southeast-1.acrcloud.com/v1/identify"

	httpMethod := "POST"
	httpURI := "/v1/identify"
	dataType := "audio"
	signatureVersion := "1"
	timestamp := strconv.FormatInt(time.Now().Unix(), 10)

	// Generate signature
	stringToSign := httpMethod + "\n" + httpURI + "\n" + accessKey + "\n" + dataType + "\n" + signatureVersion + "\n" + timestamp
	h := hmac.New(sha1.New, []byte(accessSecret))
	h.Write([]byte(stringToSign))
	signature := base64.StdEncoding.EncodeToString(h.Sum(nil))

	// Open the file
	file, err := os.Open(filePath)
	if err != nil {
		return "", fmt.Errorf("failed to open file: %v", err)
	}
	defer file.Close()

	fileInfo, err := file.Stat()
	if err != nil {
		return "", fmt.Errorf("failed to stat file: %v", err)
	}
	sampleBytes := strconv.FormatInt(fileInfo.Size(), 10)

	// Create multipart form
	var requestBody bytes.Buffer
	writer := multipart.NewWriter(&requestBody)

	// Write form fields
	writer.WriteField("access_key", accessKey)
	writer.WriteField("sample_bytes", sampleBytes)
	writer.WriteField("timestamp", timestamp)
	writer.WriteField("signature", signature)
	writer.WriteField("data_type", dataType)
	writer.WriteField("signature_version", signatureVersion)

	// Attach the file
	part, err := writer.CreateFormFile("sample", filepath.Base(filePath))
	if err != nil {
		return "", fmt.Errorf("failed to create form file: %v", err)
	}
	_, err = io.Copy(part, file)
	if err != nil {
		return "", fmt.Errorf("failed to copy file data: %v", err)
	}
	writer.Close()

	// Send HTTP request
	req, err := http.NewRequest("POST", reqURL, &requestBody)
	if err != nil {
		return "", fmt.Errorf("failed to create HTTP request: %v", err)
	}
	req.Header.Set("Content-Type", writer.FormDataContentType())

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("HTTP request failed: %v", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read response: %v", err)
	}

	return string(respBody), nil
}
