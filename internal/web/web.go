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
	"mime"
	"net"
	"net/http"
	"os"
)

// Security headers set on every response. HSTS omits `preload` because removal from the preload
// list is slow and hard to reverse. The content security policy needs no directive beyond
// `default-src` because the site loads its stylesheet and fonts from its own origin and runs no
// script. The referrer policy and the permissions policy both deny everything, because the site
// needs neither outbound referrer information nor any device feature.
const (
	strictTransportSecurity = "max-age=31536000; includeSubDomains"
	contentSecurityPolicy   = "default-src 'self'; frame-ancestors 'none'"
	contentTypeOptions      = "nosniff"
	referrerPolicy          = "no-referrer"
	permissionsPolicy       = "accelerometer=(), camera=(), geolocation=(), gyroscope=(), " +
		"magnetometer=(), microphone=(), payment=(), usb=()"
)

//go:embed templates/*.html
var templateFS embed.FS

//go:embed static
var staticFS embed.FS

type pageData struct {
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
	// net/http reads the media types of the host, and the runtime image carries no
	// /etc/mime.types. Without this line the font is served as application/octet-stream there,
	// although a development machine with a media type table serves it correctly.
	if err := mime.AddExtensionType(".woff2", "font/woff2"); err != nil {
		return nil, fmt.Errorf("registering the woff2 media type: %w", err)
	}
	layout, err := template.ParseFS(templateFS, "templates/layout.html")
	if err != nil {
		return nil, fmt.Errorf("parsing layout template: %w", err)
	}

	pages := make(map[string]*template.Template)
	for _, name := range []string{"index", "impressum", "datenschutz"} {
		page, pageErr := parsePage(layout, name)
		if pageErr != nil {
			return nil, pageErr
		}
		pages[name] = page
	}

	return &Server{pages: pages, logger: logger}, nil
}

// parsePage clones layout and adds the content template of the named page to the clone.
func parsePage(layout *template.Template, name string) (*template.Template, error) {
	page, err := layout.Clone()
	if err != nil {
		return nil, fmt.Errorf("cloning layout template for %s: %w", name, err)
	}
	if _, err = page.ParseFS(templateFS, "templates/"+name+".html"); err != nil {
		return nil, fmt.Errorf("parsing %s template: %w", name, err)
	}
	return page, nil
}

// Handler returns the HTTP handler that routes requests to the site's pages.
func (s *Server) Handler() http.Handler {
	return secureHeaders(s.routes())
}

// secureHeaders sets the site's security headers before next writes the response, so that they
// reach error responses and static files as well as the rendered pages.
func secureHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		header := w.Header()
		header.Set("Strict-Transport-Security", strictTransportSecurity)
		header.Set("Content-Security-Policy", contentSecurityPolicy)
		header.Set("X-Content-Type-Options", contentTypeOptions)
		header.Set("Referrer-Policy", referrerPolicy)
		header.Set("Permissions-Policy", permissionsPolicy)
		next.ServeHTTP(w, r)
	})
}

func (s *Server) routes() *http.ServeMux {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /{$}", s.handleIndex)
	mux.HandleFunc("GET /impressum", s.handleImpressum)
	mux.HandleFunc("GET /datenschutz", s.handleDatenschutz)
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
	s.render(w, r, "index", pageData{Title: "Sudhaus Engen", Heading: "Brauplan 2027"})
}

func (s *Server) handleImpressum(w http.ResponseWriter, r *http.Request) {
	s.render(w, r, "impressum", pageData{Title: "Impressum - Sudhaus Engen", Heading: "Impressum"})
}

func (s *Server) handleDatenschutz(w http.ResponseWriter, r *http.Request) {
	s.render(w, r, "datenschutz", pageData{
		Title:   "Datenschutzerklärung - Sudhaus Engen",
		Heading: "Datenschutzerklärung",
	})
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
		s.logger.WarnContext(r.Context(), "writing page", "page", page, "error", writeErrorReason(err))
	}
}

// writeErrorReason classifies a failed response write. A write to a client that has gone away
// returns a *net.OpError whose Source and Addr put both socket addresses into its message, so the
// raw error never reaches the log: ADR 0001 and the published Datenschutzerklärung both state that
// the logs hold no request data.
func writeErrorReason(err error) string {
	var opErr *net.OpError
	if !errors.As(err, &opErr) {
		return "write failed"
	}
	var syscallErr *os.SyscallError
	if errors.As(opErr.Err, &syscallErr) {
		return opErr.Op + ": " + syscallErr.Error()
	}
	return opErr.Op + ": connection error"
}
