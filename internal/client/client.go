package client

import (
	"bytes"
	"context"
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

type Config struct {
	Endpoint       string
	APIPrefix      string
	Username       string
	Password       string
	Token          string
	CACertPEM      string
	ClientCertPEM  string
	ClientKeyPEM   string
	Insecure       bool
	TimeoutSeconds int64
}

type Client struct {
	baseURL *url.URL
	http    *http.Client
	cfg     Config
}

type APIError struct {
	Status int
	Body   string
}

func (e *APIError) Error() string {
	return fmt.Sprintf("api error %d: %s", e.Status, e.Body)
}

func IsNotFound(err error) bool {
	if err == nil {
		return false
	}
	if apiErr, ok := err.(*APIError); ok {
		return apiErr.Status == http.StatusNotFound
	}
	return false
}

func New(cfg Config) (*Client, error) {
	if cfg.Endpoint == "" {
		return nil, fmt.Errorf("endpoint is required")
	}
	if cfg.APIPrefix == "" {
		cfg.APIPrefix = "/v3"
	}

	baseURL, err := url.Parse(cfg.Endpoint)
	if err != nil {
		return nil, fmt.Errorf("invalid endpoint: %w", err)
	}

	tlsConfig := &tls.Config{InsecureSkipVerify: cfg.Insecure} //nolint:gosec
	if cfg.CACertPEM != "" {
		pool := x509.NewCertPool()
		if !pool.AppendCertsFromPEM([]byte(cfg.CACertPEM)) {
			return nil, fmt.Errorf("failed to parse ca_cert_pem")
		}
		tlsConfig.RootCAs = pool
	}
	if cfg.ClientCertPEM != "" || cfg.ClientKeyPEM != "" {
		if cfg.ClientCertPEM == "" || cfg.ClientKeyPEM == "" {
			return nil, fmt.Errorf("both client_cert_pem and client_key_pem are required for mTLS")
		}
		cert, err := tls.X509KeyPair([]byte(cfg.ClientCertPEM), []byte(cfg.ClientKeyPEM))
		if err != nil {
			return nil, fmt.Errorf("invalid client cert/key: %w", err)
		}
		tlsConfig.Certificates = []tls.Certificate{cert}
	}

	timeout := time.Duration(cfg.TimeoutSeconds) * time.Second
	if timeout == 0 {
		timeout = 30 * time.Second
	}

	httpClient := &http.Client{
		Timeout: timeout,
		Transport: &http.Transport{
			TLSClientConfig: tlsConfig,
		},
	}

	return &Client{baseURL: baseURL, http: httpClient, cfg: cfg}, nil
}

func (c *Client) doJSON(ctx context.Context, method, path string, query url.Values, body any, out any) (*http.Response, error) {
	ref := *c.baseURL
	ref.Path = strings.TrimSuffix(ref.Path, "/") + "/" + strings.TrimPrefix(c.cfg.APIPrefix, "/")
	ref.Path = strings.TrimSuffix(ref.Path, "/") + "/" + strings.TrimPrefix(path, "/")
	if len(query) > 0 {
		ref.RawQuery = query.Encode()
	}

	var bodyReader io.Reader
	if body != nil {
		buf, err := json.Marshal(body)
		if err != nil {
			return nil, fmt.Errorf("encode request: %w", err)
		}
		bodyReader = bytes.NewBuffer(buf)
	}

	req, err := http.NewRequestWithContext(ctx, method, ref.String(), bodyReader)
	if err != nil {
		return nil, err
	}

	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if c.cfg.Token != "" {
		req.Header.Set("Authorization", "Bearer "+c.cfg.Token)
	} else if c.cfg.Username != "" || c.cfg.Password != "" {
		req.SetBasicAuth(c.cfg.Username, c.cfg.Password)
	}

	resp, err := c.http.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		b, _ := io.ReadAll(resp.Body)
		return resp, &APIError{Status: resp.StatusCode, Body: strings.TrimSpace(string(b))}
	}

	if out != nil {
		if err := json.NewDecoder(resp.Body).Decode(out); err != nil {
			return resp, fmt.Errorf("decode response: %w", err)
		}
	}

	return resp, nil
}

func (c *Client) GetJSON(ctx context.Context, path string, query url.Values, out any) error {
	_, err := c.doJSON(ctx, http.MethodGet, path, query, nil, out)
	return err
}

func (c *Client) PostJSON(ctx context.Context, path string, query url.Values, body any, out any) error {
	_, err := c.doJSON(ctx, http.MethodPost, path, query, body, out)
	return err
}

func (c *Client) PutJSON(ctx context.Context, path string, query url.Values, body any, out any) error {
	_, err := c.doJSON(ctx, http.MethodPut, path, query, body, out)
	return err
}

func (c *Client) DeleteJSON(ctx context.Context, path string, query url.Values, out any) error {
	_, err := c.doJSON(ctx, http.MethodDelete, path, query, nil, out)
	return err
}
