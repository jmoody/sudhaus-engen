package web_test

import (
	"bytes"
	"errors"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
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
	body := rec.Body.String()

	require.Contains(body, `<html lang="de">`)
	require.Contains(body, `<link rel="stylesheet" href="/static/css/site.css">`)
	require.Contains(body, "<h1>Brauplan 2027</h1>")
	require.Contains(body, "Beginn ist immer um 9:30 Uhr; Ende meist gegen 19:00 Uhr.")
	require.Contains(body, `<th scope="col">Datum</th>`)
	require.Contains(body, `<th scope="col">Bier</th>`)

	// Each row is matched whole so that no part of a date can drift away from the beer
	// beside it, and so that a visible component cannot disagree with the datetime.
	for _, row := range []struct{ date, weekday, day, month, year, beer string }{
		{"2026-11-06", "Freitag", "6.", "Nov", "2026", "Pils"},
		{"2026-12-04", "Freitag", "4.", "Dez", "2026", "Böckle"},
		{"2027-01-08", "Freitag", "8.", "Jan", "2027", "Pils"},
		{"2027-02-12", "Freitag", "12.", "Feb", "2027", "Böckle"},
		{"2027-03-26", "Freitag", "26.", "Mär", "2027", "Pils"},
		{"2027-05-27", "Donnerstag", "27.", "Mai", "2027", "Summer Ale"},
	} {
		require.Contains(body, fmt.Sprintf(
			`<time datetime=%q><span class="day-name">%s</span> <span class="day-num">%s</span> `+
				`<span class="month">%s</span> <span class="year">%s</span></time></td><td>%s</td>`,
			row.date, row.weekday, row.day, row.month, row.year, row.beer,
		))
	}

	require.NotContains(body, "<ol>")
	require.NotContains(body, "#1")
	require.NotContains(body, "November")
	require.NotContains(body, "Hello world")
}

func TestServer_Impressum(t *testing.T) {
	require := require.New(t)

	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/impressum", nil)

	newHandler(t).ServeHTTP(rec, req)

	require.Equal(http.StatusOK, rec.Code)
	require.Equal("text/html; charset=utf-8", rec.Header().Get("Content-Type"))
	require.Contains(rec.Body.String(), "<title>Impressum - Sudhaus Engen</title>")
	require.Contains(rec.Body.String(), "<h1>Impressum</h1>")
	require.Contains(rec.Body.String(), "Angaben gemäß § 18 Abs. 1 MStV")
	require.Contains(rec.Body.String(), "Joshua Moody")
	require.Contains(rec.Body.String(), "Lupfenstraße 1")
	require.Contains(rec.Body.String(), "78234 Engen")
	require.Contains(rec.Body.String(), `<a href="mailto:joshua.moody.de@gmail.com">joshua.moody.de@gmail.com</a>`)
}

func TestServer_Datenschutz(t *testing.T) {
	require := require.New(t)

	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/datenschutz", nil)

	newHandler(t).ServeHTTP(rec, req)

	require.Equal(http.StatusOK, rec.Code)
	require.Equal("text/html; charset=utf-8", rec.Header().Get("Content-Type"))
	require.Contains(rec.Body.String(), "<title>Datenschutzerklärung - Sudhaus Engen</title>")
	require.Contains(rec.Body.String(), "<h1>Datenschutzerklärung</h1>")
}

func TestServer_DatenschutzCoversArticle13(t *testing.T) {
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/datenschutz", nil)

	newHandler(t).ServeHTTP(rec, req)

	require.Equal(t, http.StatusOK, rec.Code)
	body := rec.Body.String()

	tests := []struct {
		item string
		text string
	}{
		{item: "controller identity", text: "Joshua Moody"},
		{item: "controller address", text: "Lupfenstraße 1"},
		{item: "controller contact", text: `<a href="mailto:joshua.moody.de@gmail.com">joshua.moody.de@gmail.com</a>`},
		{item: "no data protection officer", text: "Es ist kein Datenschutzbeauftragter bestellt."},
		{item: "purpose", text: "Zweck der Verarbeitung ist der Betrieb der Website"},
		{item: "legal basis", text: "Rechtsgrundlage ist Art. 6 Abs. 1 lit. f DSGVO."},
		{item: "legitimate interest", text: "zuverlässige und sichere Auslieferung der Website"},
		{item: "recipient: Microsoft as processor", text: "Auftragsverarbeiter nach Art. 28 DSGVO"},
		{item: "recipient: Microsoft as independent controller", text: "eigenständig Verantwortlicher"},
		{item: "recipient: email provider", text: "Google Ireland Limited"},
		{item: "third-country transfer", text: "EU-US Data Privacy Framework"},
		{item: "third-country safeguard", text: "Standardvertragsklauseln nach Art. 46 Abs. 2 lit. c DSGVO"},
		{item: "third-country safeguard: where published", text: `<a href="https://aka.ms/dpa">`},
		{
			item: "third-country safeguard: how to obtain a copy",
			text: "Eine Kopie der Standardvertragsklauseln können Sie",
		},
		{item: "retention", text: "Sie werden nach 30 Tagen gelöscht."},
		{item: "rights", text: "Auskunft (Art. 15 DSGVO)"},
		{
			item: "complaint",
			text: "Der Landesbeauftragte für den Datenschutz und die Informationsfreiheit Baden-Württemberg",
		},
		{item: "provision not required", text: "weder gesetzlich noch vertraglich verpflichtet"},
		{item: "no automated decision-making", text: "Profiling nach Art. 22 DSGVO findet nicht statt"},
	}

	for _, tt := range tests {
		t.Run(tt.item, func(t *testing.T) {
			require.Contains(t, body, tt.text)
		})
	}
}

// TestServer_DatenschutzMatchesSite checks the statements the notice makes about how the site works.
func TestServer_DatenschutzMatchesSite(t *testing.T) {
	require := require.New(t)

	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/datenschutz", nil)

	newHandler(t).ServeHTTP(rec, req)

	require.Equal(http.StatusOK, rec.Code)
	body := rec.Body.String()

	require.Contains(body, "setzt keine Cookies")
	require.Contains(body, "kein Analyse- oder Tracking-Werkzeug")
	require.Contains(body, "keine Ressource von einem fremden Server nachgeladen")
	require.Contains(body, "enthalten keine personenbezogenen Daten")
}

// TestServer_DatenschutzWiderspruch checks that the right to object stands apart from the other
// information, as Art. 21(4) DSGVO requires.
func TestServer_DatenschutzWiderspruch(t *testing.T) {
	require := require.New(t)

	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/datenschutz", nil)

	newHandler(t).ServeHTTP(rec, req)

	require.Equal(http.StatusOK, rec.Code)
	body := rec.Body.String()

	require.Contains(body, "<h2>9. Widerspruchsrecht</h2>")
	require.Contains(body, `<div class="notice">`)
	require.Contains(body, "Art. 21 Abs. 1 DSGVO")
}

func TestServer_FooterLegalLinks(t *testing.T) {
	for _, path := range []string{"/", "/impressum", "/datenschutz"} {
		t.Run(path, func(t *testing.T) {
			rec := httptest.NewRecorder()
			req := httptest.NewRequest(http.MethodGet, path, nil)

			newHandler(t).ServeHTTP(rec, req)

			require.Equal(t, http.StatusOK, rec.Code)
			require.Contains(t, rec.Body.String(), `<a href="/impressum">Impressum</a>`)
			require.Contains(t, rec.Body.String(), `<a href="/datenschutz">Datenschutzerklärung</a>`)
		})
	}
}

// brokenConnWriter fails every write the way net does when the peer has gone away.
type brokenConnWriter struct {
	header http.Header
	err    error
}

func (w *brokenConnWriter) Header() http.Header {
	if w.header == nil {
		w.header = make(http.Header)
	}
	return w.header
}

func (w *brokenConnWriter) Write([]byte) (int, error) { return 0, w.err }

func (w *brokenConnWriter) WriteHeader(int) {}

// TestServer_WriteFailureLogsNoClientAddress checks the no-personal-data logging rule of ADR 0001
// against the one error the site cannot control: a response write to a client that has gone away
// returns a *net.OpError whose message embeds the client's IP address and port.
func TestServer_WriteFailureLogsNoClientAddress(t *testing.T) {
	require := require.New(t)

	// Arrange
	writeErr := &net.OpError{
		Op:     "write",
		Net:    "tcp",
		Source: &net.TCPAddr{IP: net.IPv4(10, 1, 2, 3), Port: 8000},
		Addr:   &net.TCPAddr{IP: net.IPv4(203, 0, 113, 5), Port: 54321},
		Err:    &os.SyscallError{Syscall: "write", Err: errors.New("broken pipe")},
	}
	require.Contains(writeErr.Error(), "203.0.113.5", "the fixture must carry an address to be worth testing")

	var logs bytes.Buffer
	srv, err := web.NewServer(slog.New(slog.NewTextHandler(&logs, nil)))
	require.NoError(err)

	// Act
	w := &brokenConnWriter{err: writeErr}
	req := httptest.NewRequest(http.MethodGet, "/datenschutz", nil)
	srv.Handler().ServeHTTP(w, req)

	// Assert
	logged := logs.String()
	require.Contains(logged, "writing page")
	require.NotContains(logged, "203.0.113.5", "the client address must not reach the log")
	require.NotContains(logged, "54321", "the client port must not reach the log")
	require.NotContains(logged, "10.1.2.3", "the server address must not reach the log")
	require.Contains(logged, "write: broken pipe", "the reason for the failure is still useful")
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
