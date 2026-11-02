// Package web serves the Sudhaus Engen site over HTTP.
package web

import (
	"bytes"
	"embed"
	"errors"
	"fmt"
	"html/template"
	"io/fs"
	"log/slog"
	"net/http"
)

//go:embed templates/*.html
var templateFS embed.FS

//go:embed static
var staticFS embed.FS

type indexData struct {
	Title   string
	Heading string
}

// Server renders the site's pages from embedded templates.
type Server struct {
	pages  map[string]*template.Template
	logger *slog.Logger
}

// NewServer parses the embedded templates and returns a Server that logs to logger.
func NewServer(logger *slog.Logger) (*Server, error) {
	if logger == nil {
		return nil, errors.New("logger is nil")
	}
	layout, err := template.ParseFS(templateFS, "templates/layout.html")
	if err != nil {
		return nil, fmt.Errorf("parsing layout template: %w", err)
	}

	pages := make(map[string]*template.Template)
	index, err := layout.Clone()
	if err != nil {
		return nil, fmt.Errorf("cloning layout template for index: %w", err)
	}
	if _, err = index.ParseFS(templateFS, "templates/index.html"); err != nil {
		return nil, fmt.Errorf("parsing index template: %w", err)
	}
	pages["index"] = index

	return &Server{pages: pages, logger: logger}, nil
}

// Handler returns the HTTP handler that routes requests to the site's pages.
func (s *Server) Handler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /{$}", s.handleIndex)
	staticFiles, err := fs.Sub(staticFS, "static")
	if err != nil {
		s.logger.Error("opening embedded static files", "error", err)
		mux.HandleFunc("GET /static/", func(w http.ResponseWriter, _ *http.Request) {
			http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
		})
		return mux
	}
	mux.Handle("GET /static/", http.StripPrefix("/static/", http.FileServer(http.FS(staticFiles))))
	return mux
}

func (s *Server) handleIndex(w http.ResponseWriter, r *http.Request) {
	s.render(w, r, "index", indexData{Title: "Sudhaus Engen", Heading: "Hello world"})
}

func (s *Server) render(w http.ResponseWriter, r *http.Request, page string, data any) {
	var buf bytes.Buffer
	pageTemplate, ok := s.pages[page]
	if !ok {
		s.logger.ErrorContext(r.Context(), "rendering page", "page", page, "error", "template not found")
		http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
		return
	}
	if err := pageTemplate.ExecuteTemplate(&buf, "layout", data); err != nil {
		s.logger.ErrorContext(r.Context(), "rendering page", "page", page, "error", err)
		http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	if _, err := buf.WriteTo(w); err != nil {
		s.logger.WarnContext(r.Context(), "writing page", "page", page, "error", err)
	}
}
