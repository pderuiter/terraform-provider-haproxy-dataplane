package provider

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/hashicorp/terraform-plugin-framework/diag"
	"github.com/pderuiter/terraform-provider-haproxy-dataplane/internal/client"
)

func getClient(data any) (*client.Client, diag.Diagnostics) {
	var diags diag.Diagnostics
	if data == nil {
		diags.AddError("Provider not configured", "Provider configuration missing")
		return nil, diags
	}
	c, ok := data.(*client.Client)
	if !ok {
		diags.AddError("Provider not configured", "Unexpected provider data type")
		return nil, diags
	}
	return c, diags
}

func normalizeJSON(input string) (string, map[string]any, error) {
	var obj map[string]any
	if err := json.Unmarshal([]byte(input), &obj); err != nil {
		return "", nil, fmt.Errorf("invalid json: %w", err)
	}
	buf, err := json.Marshal(obj)
	if err != nil {
		return "", nil, err
	}
	return string(buf), obj, nil
}

func decodeJSONToMap(input string) (map[string]any, error) {
	var obj map[string]any
	if err := json.Unmarshal([]byte(input), &obj); err != nil {
		return nil, err
	}
	return obj, nil
}

func encodeJSON(input any) (string, error) {
	buf, err := json.Marshal(input)
	if err != nil {
		return "", err
	}
	return string(buf), nil
}

func getConfigVersion(ctx context.Context, c *client.Client) (int64, error) {
	var out int64
	if err := c.GetJSON(ctx, "/services/haproxy/configuration/version", nil, &out); err != nil {
		return 0, err
	}
	return out, nil
}

func int64ToString(v int64) string {
	return fmt.Sprintf("%d", v)
}
