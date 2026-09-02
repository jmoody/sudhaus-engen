---
description: 'Go coding standards and practices for all Go code in this project'
applyTo: "**/*.go,**/go.mod,**/go.sum"
---

# Go development instructions

## General instructions

- Write simple, clear, and idiomatic Go code
- Favor clarity and simplicity over cleverness
- Follow the principle of least surprise
- Keep the happy path left-aligned (minimize indentation)
- Return early to reduce nesting; use `if condition { return }` to avoid else blocks
- Make the zero value useful
- Write self-documenting code with clear, descriptive names
- Document exported types, functions, methods, and packages
- Use Go modules for dependency management
- Leverage the Go standard library instead of reinventing the wheel (e.g., use `strings.Builder` for string concatenation, `filepath.Join` for path construction)
- Prefer standard library solutions over custom implementations when functionality exists

## Naming conventions

### Packages

- Use lowercase, single-word package names
- Avoid underscores, hyphens, or mixedCaps
- Choose names that describe what the package provides, not what it contains
- Avoid generic names like `util`, `common`, or `base`
- Package names should be singular, not plural

### Package declaration rules (CRITICAL)

- **NEVER duplicate `package` declarations** - each Go file must have exactly ONE `package` line
- When editing an existing `.go` file:
  - **PRESERVE** the existing `package` declaration - do not add another one
  - If you need to replace the entire file content, start with the existing package name
- When creating a new `.go` file:
  - **BEFORE writing any code**, check what package name other `.go` files in the same directory use
  - Use the SAME package name as existing files in that directory
  - If it is a new directory, use the directory name as the package name
  - Write **exactly one** `package <name>` line at the very top of the file
- When using file creation or replacement tools:
  - **ALWAYS verify** the target file does not already have a `package` declaration before adding one
  - If replacing file content, include only ONE `package` declaration in the new content
  - **NEVER** create files with multiple `package` lines or duplicate declarations

### Variables and functions

- Use mixedCaps or MixedCaps (camelCase) rather than underscores
- Variables with a limited scope should be single-letter, double-letter, or three-letter variables
- Use meaningful names for variables with broader scope
- Follow Go idioms and conventions
- Use camelCase for unexported variables and PascalCase for exported variables
- Avoid abbreviations unless they are widely understood in the domain
- Avoid stuttering (e.g., avoid `http.HTTPServer`, prefer `http.Server`)

### Interfaces

- Name interfaces with -er suffix when possible (e.g., `Reader`, `Writer`, `Formatter`)
- Single-method interfaces should be named after the method (e.g., `Read` → `Reader`)
- Keep interfaces small and focused (1-3 methods is ideal)
- Accept interfaces, return concrete types
- Define interfaces close to where they are used, not where they are implemented
- Do not export interfaces unless necessary

### Constants

- Use MixedCaps for exported constants
- Use mixedCaps for unexported constants
- Group related constants using `const` blocks
- Consider using typed constants for better type safety

## Type declarations

### Use `any` instead of `interface{}`

- Use the `any` type alias (Go 1.18+) instead of the legacy `interface{}` syntax
- Prefer generics over unconstrained types; when an unconstrained type is truly needed, use `any`
- This improves code readability and follows modern Go practices

```go
// ✅ Good: Modern Go syntax
func Process(data any) error {
    // ...
}

func ParseConfig(input any) (*Config, error) {
    // ...
}

// ❌ Bad: Legacy syntax
func Process(data interface{}) error {
    // ...
}

func ParseConfig(input interface{}) (*Config, error) {
    // ...
}
```

**Exception**: When working with external libraries that use `interface{}` in their APIs, match their signature for compatibility.

### Pointers vs values

- Use pointer receivers for large structs or when you need to modify the receiver
- Use value receivers for small structs and when immutability is desired
- Use pointer parameters when you need to modify the argument or for large structs
- Use value parameters for small structs and when you want to prevent modification
- Be consistent within a type's method set
- Consider the zero value when choosing pointer vs value receivers

## Method and function naming

Do not use "Get" and "Set" prefixes on method names; use clear, descriptive names without prefixes.

### ❌ Avoid these patterns:
- `GetSecret()` → Use `SecretForName()` or `Secret()`
- `SetEndpoint()` → Use `UseEndpoint()` or `WithEndpoint()`
- `GetBuildInfo()` → Use `BuildInfo()` or `Current()`
- `getEnvOrDefault()` → Use `envOrDefault()`

### ✅ Prefer these patterns:
- Functions that return values: `Current()`, `Load()`, `Parse()`
- Functions that configure: `Use()`, `With()`, `Configure()`
- Functions that retrieve by key: `ForName()`, `ByID()`, `Lookup()`

**Note**: This applies to ALL functions and methods, including:
- Private functions (starting with lowercase)
- Test functions (e.g., `TestConfig_GetServerAddr` → `TestConfig_ServerAddr`)
- Method receivers on structs

## Package design

- Use meaningful package names that reflect their purpose
- Prefer composition over inheritance
- Keep packages focused on a single responsibility
- Avoid circular dependencies
- Follow standard Go project layout conventions
- Keep `main` packages in `cmd/` directory
- Put reusable packages in `internal/`
- Use `internal/` for packages that should not be imported by external projects

## Function design

- Keep functions small and focused on a single responsibility
- Prefer switch statements over long if-else chains when checking multiple values
- Use early returns to reduce nesting
- Limit function parameters (consider using structs for multiple parameters)

## Error handling

- Always handle errors explicitly
- Use Go's idiomatic error handling patterns
- Wrap errors with context using `fmt.Errorf` with `%w` verb
- Don't ignore errors or use blank identifiers for error returns
- Return errors as the last return value
- Name error variables `err`
- Keep error messages lowercase and do not end with punctuation
- Use `errors.Is` and `errors.As` for error checking
- Create custom error types for domain-specific errors
- Export error variables for sentinel errors
- Do not log and return errors (choose one)

```go
// Good: Explicit error handling with context
result, err := someOperation()
if err != nil {
    return fmt.Errorf("performing operation: %w", err)
}

// Bad: Ignoring errors
result, _ := someOperation()
```

### Defensive programming

When writing helper functions that accept pointers or interfaces, don't silently succeed on nil inputs. Return explicit errors with meaningful messages:

```go
// Good: Return explicit error on nil input
func StartTokenProvider(ctx context.Context, tp TokenProvider) error {
    if tp == nil {
        return errors.New("TokenProvider is nil")  // Fail loudly with clear message
    }
    return tp.Start(ctx)
}

// Bad: Silently succeed on nil input (masks bugs)
func StartTokenProvider(ctx context.Context, tp TokenProvider) error {
    if tp == nil {
        return nil  // ❌ Caller thinks it succeeded
    }
    return tp.Start(ctx)
}
```

This approach:
- Makes bugs visible immediately rather than causing mysterious failures later
- Provides clear error messages for debugging
- Allows callers to handle the error appropriately

## Memory management

- Minimize allocations in hot paths
- Reuse objects when possible (consider `sync.Pool`)
- Use value receivers for small structs
- Preallocate slices when size is known: `make([]T, 0, expectedLen)`
- Avoid unnecessary string conversions

### I/O: readers and buffers

- Most `io.Reader` streams are consumable once; reading advances state. Do not assume a reader can be re-read without special handling
- If you must read data multiple times, buffer it once and recreate readers on demand:
  - Use `io.ReadAll` (or a limited read) to obtain `[]byte`, then create fresh readers via `bytes.NewReader(buf)` or `bytes.NewBuffer(buf)` for each reuse
  - For strings, use `strings.NewReader(s)`; you can `Seek(0, io.SeekStart)` on `*bytes.Reader` to rewind
- For HTTP requests, do not reuse a consumed `req.Body`. Instead:
  - Keep the original payload as `[]byte` and set `req.Body = io.NopCloser(bytes.NewReader(buf))` before each send
  - Prefer configuring `req.GetBody` so the transport can recreate the body for redirects/retries: `req.GetBody = func() (io.ReadCloser, error) { return io.NopCloser(bytes.NewReader(buf)), nil }`
- To duplicate a stream while reading, use `io.TeeReader` (copy to a buffer while passing through) or write to multiple sinks with `io.MultiWriter`
- Reusing buffered readers: call `(*bufio.Reader).Reset(r)` to attach to a new underlying reader; do not expect it to "rewind" unless the source supports seeking
- For large payloads, avoid unbounded buffering; consider streaming, `io.LimitReader`, or on-disk temporary storage to control memory

### `io.Pipe` for streaming

- Use `io.Pipe` to stream without buffering the whole payload
- Write to `*io.PipeWriter` in a separate goroutine while the reader consumes
- Always close the writer; use `CloseWithError(err)` on failures
- `io.Pipe` is for streaming, not rewinding or making readers reusable

**Warning**: When using `io.Pipe` (especially with multipart writers), all writes must be performed in strict, sequential order. Do not write concurrently or out of order. Multipart boundaries and chunk order must be preserved.

## HTTP client design

- Keep the client struct focused on configuration and dependencies only (e.g., base URL, `*http.Client`, auth, default headers). It must not store per-request state
- Do not store or cache `*http.Request` inside the client struct, and do not persist request-specific state across calls; instead, construct a fresh request per method invocation
- Methods should accept `context.Context` and input parameters, assemble the `*http.Request` locally, then call `c.httpClient.Do(req)`
- If request-building logic is reused, factor it into unexported helper functions or a per-call builder type; never keep `http.Request` (URL params, body, headers) as fields on the long-lived client
- Ensure the underlying `*http.Client` is configured (timeouts, transport) and is safe for concurrent use; avoid mutating `Transport` after first use
- Always set headers on the request instance you are sending, and close response bodies (`defer resp.Body.Close()`), handling errors appropriately

## HTTP handler design

This project uses `go-chi/chi/v5` for routing. Routes are registered in `internal/api/rest/routes.go`.

- Use `chi.Router.Route(pattern, fn)` for nested route groups
- Use `r.Handle(path, http.HandlerFunc(fn))` for leaf routes
- Use `r.Use(middleware)` to apply middleware to a route group
- Extract path parameters with `r.PathValue("name")` (Go 1.22+ stdlib, compatible with chi v5)
- Handlers are standard `func(w http.ResponseWriter, r *http.Request)` signatures
- Use middleware as `func(http.Handler) http.Handler` for cross-cutting concerns (auth, environment gating)
- Return appropriate HTTP status codes; use `http.Error` for error responses
- Set `Content-Type` header explicitly on all responses
- For JSON responses, use `json.NewEncoder(w).Encode(data)` after setting the content type
- Validate request inputs before processing

### JSON handling

- Use struct tags to control JSON marshaling: `json:"fieldName,omitempty"`
- Validate input data after decoding; do not trust client input
- Use `json.NewDecoder(r.Body).Decode(&v)` for request bodies (not `io.ReadAll` + `json.Unmarshal`)
- Use pointer fields for optional JSON properties that distinguish between zero value and absent
- Handle JSON errors explicitly; return `http.StatusBadRequest` for malformed input
- Set `Content-Type: application/json` before writing JSON responses

## Testing standards

- Generate Spec style unit tests unless specifically asked to generate case-style tests
- **Always use `testify/require` for assertions - never use `testify/assert`**
- Mock external dependencies and backing services
- Ensure tests are isolated and can run in any order
- Test both happy path and error conditions
- Use table-driven tests for multiple test cases
- Follow naming convention: `TestFunction_Scenario` (without Get prefix)
- Mark helper functions with `t.Helper()`
- Create test fixtures for complex setup
- Clean up resources using `t.Cleanup()`

```go
// Good: Spec style test with testify/require
func TestConfig_ServerAddr(t *testing.T) {
    require := require.New(t)

    config := &Config{Port: "8080"}
    addr := config.ServerAddr()

    require.Equal(":8080", addr)
}
```

### Require vs assert guidelines

**Use `require` exclusively** in all test code. The `require` functions stop test execution immediately on failure, which is the correct behavior for almost all test scenarios.

```go
// Good: Using require stops test immediately on failure
func TestValidateConfig(t *testing.T) {
    cfg, err := LoadConfig()
    require.NoError(t, err)  // If this fails, don't continue
    require.NotNil(t, cfg)    // Config is needed for rest of test

    require.Equal(t, "production", cfg.Environment())
}

// Bad: Using assert continues after failure, causing cascading errors
func TestValidateConfig(t *testing.T) {
    cfg, err := LoadConfig()
    assert.NoError(t, err)  // ❌ Wrong: test continues even if cfg is nil
    assert.NotNil(t, cfg)   // ❌ Wrong: may panic on next line if cfg is nil

    assert.Equal(t, "production", cfg.Environment())  // ❌ Panic if cfg is nil
}
```

**Rare exceptions where `assert` is required**:

1. **HTTP handlers in test mock servers**: When using `httptest.NewServer` with handler functions, the handler runs in a separate goroutine. Using `require` (which calls `t.FailNow()`) will terminate only that goroutine, not the test. Use `assert` in these handlers.

2. **Other goroutines in tests**: Similarly, any test code running in a goroutine spawned by the test should use `assert` instead of `require`.

3. **Multiple independent checks** (least common): When testing multiple independent conditions where seeing all failures at once provides value.

```go
// Required use of assert: HTTP handler in test mock server
func TestAPICall(t *testing.T) {
    server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        // Must use assert in handlers - require would only kill this goroutine
        assert.Equal(t, "POST", r.Method)
        assert.Equal(t, "application/json", r.Header.Get("Content-Type"))
        w.WriteHeader(http.StatusOK)
    }))
    defer server.Close()

    // Use require in the main test goroutine
    resp, err := http.Post(server.URL, "application/json", nil)
    require.NoError(t, err)
    require.Equal(t, http.StatusOK, resp.StatusCode)
}

// Acceptable use of assert (rare): Testing multiple independent properties
func TestMultipleIndependentProperties(t *testing.T) {
    obj := CreateTestObject()
    require.NotNil(t, obj)  // Still use require for prerequisites

    // All these checks are independent - seeing all failures at once is valuable
    assert.Equal(t, "expected", obj.Name)
    assert.Equal(t, 42, obj.Count)
    assert.True(t, obj.IsValid)
}
```

**Best practice**: For multiple property checks, prefer using subtests with `require` instead:

```go
// Better: Use subtests instead of assert
func TestMultipleIndependentProperties(t *testing.T) {
    obj := CreateTestObject()
    require.NotNil(t, obj)

    t.Run("name", func(t *testing.T) {
        require.Equal(t, "expected", obj.Name)
    })

    t.Run("count", func(t *testing.T) {
        require.Equal(t, 42, obj.Count)
    })

    t.Run("validity", func(t *testing.T) {
        require.True(t, obj.IsValid)
    })
}
```

### In suite tests, use `s.Require()` not `s`

In testify suite methods, `s.Equal()`, `s.True()`, `s.Contains()`, etc. are all **assert-style** - they continue after failure. Always call `s.Require()` first:

```go
// Good: s.Require().Equal() stops on failure
func (s *MySuite) TestHandler_ReturnsError() {
    // Arrange
    w := httptest.NewRecorder()
    req := httptest.NewRequest(http.MethodGet, "/test", http.NoBody)

    // Act
    s.handler.ServeHTTP(w, req)

    // Assert
    s.Require().Equal(http.StatusBadRequest, w.Code)
    s.Require().Contains(w.Body.String(), "invalid input")
    s.Require().NotEmpty(w.Header().Get("Content-Type"))
}

// Bad: s.Equal() continues after failure
func (s *MySuite) TestHandler_ReturnsError() {
    w := httptest.NewRecorder()
    req := httptest.NewRequest(http.MethodGet, "/test", http.NoBody)

    s.handler.ServeHTTP(w, req)

    s.Equal(http.StatusBadRequest, w.Code)       // ❌ Continues on failure
    s.Contains(w.Body.String(), "invalid input") // ❌ May fail with confusing output
    s.NotEmpty(w.Header().Get("Content-Type"))    // ❌ Cascading failures
}
```

## Coding best practices

- Follow idiomatic Go patterns and keep code maintainable and DRY
- Prefer dependency injection for testability and modularity
- Use interfaces for dependencies to support testing
- Use error wrapping with context information
- Use structured error handling and custom error types if needed
- Use context propagation and explicit error handling
- Use `_test` package name suffix for test files
- When asked to generate tests, keep it simple, focused, and only cover what's important
- When creating mocks, use go.uber.org/mock/mockgen
- Run `make lint` after your changes and fix any linting errors you newly introduce
- Use `defer` for resource cleanup
- Use constants for timeouts and repeated values

## Testing and quality

- Run all tests using `make test`
- Always write unit tests for new code and ensure all existing tests pass
- Organize tests with testify suites or table-driven tests
- Use clear, descriptive test names
- Mock external dependencies for reliable unit testing
- Document the intent of each test suite using a doc comment on the suite struct. Use short section headers like `// Arrange`, `// Act`, and `// Assert` if helpful, but avoid sentence-style narration of individual test steps.
- Use `suite.Run(t, new(MyTestSuite))` as the entry point for each suite, and ensure tests are deterministic and do not depend on external state
- Structure tests using Arrange/Act/Assert pattern: setup inputs and mocks, execute the code under test, then verify results

Example test skeleton:

```go
func (s *MyTestSuite) TestMyFunction_Scenario() {
    // Arrange

    // Act

    // Assert
    s.Require().NoError(err)
    s.Require().Equal(expected, actual)
}
```

## Code comments

- Keep comments up-to-date as code changes, to prevent misleading or outdated information
- All comments should always reflect the current state of the code. Comments should NOT chronicle change over time
- Do not remove commented out code
- Write comments in complete sentences
- Start comments on exported symbols with the name of the thing being described
- Package comments should start with "Package [name]"
- Document why, not what, unless the what is complex

### Do not write procedural narration comments

**Never add comments that restate what the next line of code does.** This is the single most common mistake in AI-generated code. If a comment merely narrates the operation, delete it. The code already says what it does.

Banned patterns (delete on sight):

```go
// ❌ Bad: Every one of these restates the next line
// Create the request
req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, body)

// Marshal the request to JSON
jsonData, err := json.Marshal(req)

// Send the HTTP request
resp, err := client.Do(req)

// Read the response body
respBody, err := io.ReadAll(resp.Body)

// Parse the response
if err := json.Unmarshal(respBody, &result); err != nil {

// Check for errors
if err != nil {

// Set default options
if options == nil {
    options = &ClientOptions{}
}

// Execute the operation with retries
if err := backoff.Retry(operation, b); err != nil {

// Verify that the server returns 200
require.Equal(t, http.StatusOK, resp.StatusCode)

// Register jobs
if err := jobs.Register(host); err != nil {

// Default values
const (
    defaultTimeout = 30 * time.Second
)
```

A comment is warranted only when it explains *why* - a non-obvious design decision, a workaround, a constraint, or a subtle gotcha:

```go
// ✅ Good: Explains WHY, not what
// Use a temporary client to avoid infinite recursion through refreshAccessToken
tempClient := &http.Client{Timeout: c.httpClient.Timeout}

// Port API limits bulk upserts to 20 entities per request
const maxBatchSize = 20

// Allow all authenticated services - fine-grained authorization is handled downstream
func(_ context.Context, _ string, _ bool) bool { return true }
```

## Code organization

- Group imports in standard library, third-party, and local packages
- Use `gofmt` and `goimports` for consistent formatting
- Use meaningful variable names instead of comments

## Concurrency

- Use channels to communicate between goroutines
- Follow the principle: "Don't communicate by sharing memory; share memory by communicating"
- Use sync package primitives (Mutex, RWMutex) only when channels are not appropriate
- Always handle goroutine lifecycle properly. Always know how a goroutine will exit
- Use context.Context for cancellation and timeouts
- Be cautious about creating goroutines in libraries; prefer letting the caller control concurrency
- Use `sync.Once` for one-time initialization
- Use `sync.RWMutex` when you have many readers and few writers
- Keep critical sections small
- Close channels from the sender side, not the receiver
- Use buffered channels when the capacity is known ahead of time
- Use `select` with a `default` case for non-blocking channel operations

### WaitGroup usage (Go 1.25+)

This project uses Go 1.25+. Use the `WaitGroup.Go` method instead of the classic `Add`/`Done` pattern:

```go
// ✅ Good: Go 1.25+ WaitGroup.Go
var wg sync.WaitGroup
wg.Go(func() {
    processItem(item1)
})
wg.Go(func() {
    processItem(item2)
})
wg.Wait()

// ❌ Avoid: Classic Add/Done pattern (unnecessary in Go 1.25+)
var wg sync.WaitGroup
wg.Add(2)
go func() {
    defer wg.Done()
    processItem(item1)
}()
go func() {
    defer wg.Done()
    processItem(item2)
}()
wg.Wait()
```

## Configuration and environment

- Use struct tags for environment variable binding
- Validate all required configuration at startup
- Provide sensible defaults for development environments
- Use structured configuration with clear naming conventions

```go
// Good: Configuration struct with validation
type Config struct {
    Port     string `env:"PORT" envDefault:"8080"`
    DBUrl    string `env:"DATABASE_URL,required"`
    LogLevel string `env:"LOG_LEVEL" envDefault:"info"`
}
```

## Logging

### Log levels

- `Debug` - successful HTTP responses, cache hits/misses
- `Info` - operational milestones (job completed, cache backend selected, request processed)
- `Warn` - recoverable issues (rate limits, missing config fallbacks, evaluation failures)
- `Error` - unrecoverable failures (startup errors, HTTP 5xx from dependencies)

## Dependencies

- Use Go modules for dependency management
- Pin specific versions for reproducible builds
- Regularly update dependencies for security patches
- Minimize external dependencies
- Use `make tidy` to clean up unused dependencies

## Common pitfalls to avoid

- Not checking errors
- Ignoring race conditions
- Creating goroutine leaks
- Not using defer for cleanup
- Modifying maps concurrently
- Not understanding nil interfaces vs nil pointers
- Forgetting to close resources (files, connections, response bodies)
- Using global variables unnecessarily
- Over-using unconstrained types (e.g., `any`); prefer specific types or generic type parameters with constraints
- Not considering the zero value of types
- **Creating duplicate `package` declarations** - this is a compile error; always check existing files before adding package declarations
- Reusing consumed `io.Reader` / `req.Body` without rebuffering (see [Memory management](#memory-management))
- Storing per-request state on long-lived HTTP client structs (see [HTTP client design](#http-client-design))
- Using `Get`/`Set` prefixes on method names (see [Method and function naming](#method-and-function-naming))
