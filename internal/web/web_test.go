package web_test

import (
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/jmoody/sudhaus-engen/internal/web"
)

func newHandler(t *testing.T) http.Handler {
	t.Helper()

	srv, err := web.NewServer(slog.New(slog.DiscardHandler))
	require.NoError(t, err)
	return srv.Handler()
}

func TestNewServer_NilLogger(t *testing.T) {
	srv, err := web.NewServer(nil)

	require.Error(t, err)
	require.Nil(t, srv)
}

func TestServer_FrontPage(t *testing.T) {
	require := require.New(t)

	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/", nil)

	newHandler(t).ServeHTTP(rec, req)

	require.Equal(http.StatusOK, rec.Code)
	require.Equal("text/html; charset=utf-8", rec.Header().Get("Content-Type"))
	require.Contains(rec.Body.String(), `<html lang="de">`)
	require.Contains(rec.Body.String(), `<link rel="stylesheet" href="/static/css/site.css">`)
	require.Contains(rec.Body.String(), "<h1>Hello world</h1>")
}

func TestServer_StaticFiles(t *testing.T) {
	tests := []struct {
		name        string
		path        string
		status      int
		contentType string
	}{
		{
			name:        "stylesheet",
			path:        "/static/css/site.css",
			status:      http.StatusOK,
			contentType: "text/css; charset=utf-8",
		},
		{
			name:        "font",
			path:        "/static/fonts/InconsolataNerdFontMono-Regular.ttf",
			status:      http.StatusOK,
			contentType: "font/ttf",
		},
		{
			name:        "bold font",
			path:        "/static/fonts/InconsolataNerdFontMono-Bold.ttf",
			status:      http.StatusOK,
			contentType: "font/ttf",
		},
		{
			name:   "unknown asset",
			path:   "/static/missing",
			status: http.StatusNotFound,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rec := httptest.NewRecorder()
			req := httptest.NewRequest(http.MethodGet, tt.path, nil)

			newHandler(t).ServeHTTP(rec, req)

			require.Equal(t, tt.status, rec.Code)
			if tt.contentType != "" {
				require.Equal(t, tt.contentType, rec.Header().Get("Content-Type"))
				require.NotEmpty(t, rec.Body.Bytes())
			}
		})
	}
}

func TestServer_UnknownPath(t *testing.T) {
	require := require.New(t)

	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/missing", nil)

	newHandler(t).ServeHTTP(rec, req)

	require.Equal(http.StatusNotFound, rec.Code)
}

func TestServer_PostFrontPage(t *testing.T) {
	require := require.New(t)

	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/", nil)

	newHandler(t).ServeHTTP(rec, req)

	require.Equal(http.StatusMethodNotAllowed, rec.Code)
}
