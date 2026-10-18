// Package web serves the Sudhaus Engen site over HTTP.
package web

import (
	"bytes"
	"embed"
	"errors"
	"fmt"
	"html/template"
	"log/slog"
	"net/http"
)

//go:embed templates/*.html
var templateFS embed.FS

type indexData struct {
	Title   string
	Heading string
}

// Server renders the site's pages from embedded templates.
type Server struct {
	index  *template.Template
	logger *slog.Logger
}

// NewServer parses the embedded templates and returns a Server that logs to logger.
func NewServer(logger *slog.Logger) (*Server, error) {
	if logger == nil {
		return nil, errors.New("logger is nil")
	}
	index, err := template.ParseFS(templateFS, "templates/index.html")
	if err != nil {
		return nil, fmt.Errorf("parsing index template: %w", err)
	}
	return &Server{index: index, logger: logger}, nil
}

// Handler returns the HTTP handler that routes requests to the site's pages.
func (s *Server) Handler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /{$}", s.handleIndex)
	return mux
}

func (s *Server) handleIndex(w http.ResponseWriter, r *http.Request) {
	var buf bytes.Buffer
	data := indexData{Title: "Sudhaus Engen", Heading: "Hello world"}
	if err := s.index.Execute(&buf, data); err != nil {
		s.logger.ErrorContext(r.Context(), "rendering index page", "error", err)
		http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	if _, err := buf.WriteTo(w); err != nil {
		s.logger.WarnContext(r.Context(), "writing index page", "error", err)
	}
}
