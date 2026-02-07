package provider

import (
	"context"
	"fmt"
	"strings"

	"github.com/hashicorp/terraform-plugin-framework/attr"
	"github.com/hashicorp/terraform-plugin-framework/diag"
	"github.com/hashicorp/terraform-plugin-framework/types"
	"github.com/hashicorp/terraform-plugin-framework/types/basetypes"
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

func objectToMap(ctx context.Context, obj types.Object) (map[string]any, diag.Diagnostics) {
	var out map[string]any
	diags := obj.As(ctx, &out, basetypes.ObjectAsOptions{UnhandledNullAsEmpty: true, UnhandledUnknownAsEmpty: false})
	if out == nil {
		out = map[string]any{}
	}
	return out, diags
}

func mapToObject(ctx context.Context, typesMap map[string]attr.Type, input map[string]any, dropKeys []string) (types.Object, diag.Diagnostics) {
	filtered := map[string]any{}
	for k, v := range input {
		filtered[k] = v
	}
	for _, k := range dropKeys {
		delete(filtered, k)
	}
	obj, diags := types.ObjectValueFrom(ctx, typesMap, filtered)
	return obj, diags
}

func buildPath(path string, params map[string]string) string {
	out := path
	for k, v := range params {
		out = strings.ReplaceAll(out, "{"+k+"}", v)
	}
	return out
}

func listObjectsFrom(ctx context.Context, typesMap map[string]attr.Type, input []map[string]any) (types.List, diag.Diagnostics) {
	list, diags := types.ListValueFrom(ctx, types.ObjectType{AttrTypes: typesMap}, input)
	return list, diags
}
