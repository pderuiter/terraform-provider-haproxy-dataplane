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

func applyWithVersionRetry(ctx context.Context, c *client.Client, fn func(version int64) error) error {
	const maxAttempts = 5
	var lastErr error
	for attempt := 0; attempt < maxAttempts; attempt++ {
		version, err := getConfigVersion(ctx, c)
		if err != nil {
			return err
		}
		err = fn(version)
		if err == nil {
			return nil
		}
		if isVersionMismatch(err) {
			lastErr = err
			continue
		}
		return err
	}
	return lastErr
}

func isVersionMismatch(err error) bool {
	if err == nil {
		return false
	}
	if apiErr, ok := err.(*client.APIError); ok {
		return apiErr.Status == 409 && strings.Contains(apiErr.Body, "version mismatch")
	}
	return false
}

func int64ToString(v int64) string {
	return fmt.Sprintf("%d", v)
}

func objectToMap(ctx context.Context, obj types.Object) (map[string]any, diag.Diagnostics) {
	if obj.IsNull() || obj.IsUnknown() {
		return map[string]any{}, nil
	}
	out := map[string]any{}
	var diags diag.Diagnostics
	for k, v := range obj.Attributes() {
		val, vDiags := attrValueToAny(ctx, v)
		diags.Append(vDiags...)
		out[k] = val
	}
	return out, diags
}

func objectToMapWithSchema(ctx context.Context, obj types.Object, schemaName string) (map[string]any, diag.Diagnostics) {
	out, diags := objectToMap(ctx, obj)
	meta, ok := schemaMetaFor(schemaName)
	if !ok || meta == nil {
		return out, diags
	}
	return transformTFToAPIMap(out, meta), diags
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

func mapToObjectWithSchema(ctx context.Context, schemaName string, input map[string]any, dropKeys []string) (types.Object, diag.Diagnostics) {
	meta, ok := schemaMetaFor(schemaName)
	if ok && meta != nil {
		input = transformAPIToTFMap(input, meta)
		dropKeys = dropKeysToTF(meta, dropKeys)
	}
	input = dropDynamicAttrs(schemaName, input)
	for _, k := range dropKeys {
		delete(input, k)
	}
	typesMap := mustSchemaAttrTypes(schemaName)
	obj, diags := objectFromMap(ctx, typesMap, input)
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

func listObjectsFromSchema(ctx context.Context, schemaName string, input []map[string]any) (types.List, diag.Diagnostics) {
	meta, ok := schemaMetaFor(schemaName)
	if ok && meta != nil {
		converted := make([]map[string]any, 0, len(input))
		for _, item := range input {
			converted = append(converted, transformAPIToTFMap(item, meta))
		}
		input = converted
	}
	filtered := make([]map[string]any, 0, len(input))
	for _, item := range input {
		filtered = append(filtered, dropDynamicAttrs(schemaName, item))
	}
	input = filtered
	return listObjectsFrom(ctx, mustSchemaAttrTypes(schemaName), input)
}

func listToObjectsWithSchema(ctx context.Context, list types.List, schemaName string) ([]map[string]any, diag.Diagnostics) {
	var out []map[string]any
	diags := list.ElementsAs(ctx, &out, true)
	if out == nil {
		out = []map[string]any{}
	}
	meta, ok := schemaMetaFor(schemaName)
	if ok && meta != nil {
		for i, item := range out {
			out[i] = transformTFToAPIMap(item, meta)
		}
	}
	return out, diags
}

func attrValueToAny(ctx context.Context, val attr.Value) (any, diag.Diagnostics) {
	if val == nil {
		return nil, nil
	}
	if val.IsNull() || val.IsUnknown() {
		return nil, nil
	}
	switch v := val.(type) {
	case types.String:
		return v.ValueString(), nil
	case types.Int64:
		return v.ValueInt64(), nil
	case types.Bool:
		return v.ValueBool(), nil
	case types.Float64:
		return v.ValueFloat64(), nil
	case types.Object:
		return objectToMap(ctx, v)
	case types.List:
		values := v.Elements()
		out := make([]any, 0, len(values))
		var diags diag.Diagnostics
		for _, item := range values {
			c, cDiags := attrValueToAny(ctx, item)
			diags.Append(cDiags...)
			out = append(out, c)
		}
		return out, diags
	case types.Map:
		values := v.Elements()
		out := map[string]any{}
		var diags diag.Diagnostics
		for key, item := range values {
			c, cDiags := attrValueToAny(ctx, item)
			diags.Append(cDiags...)
			out[key] = c
		}
		return out, diags
	case types.Dynamic:
		if v.IsNull() || v.IsUnknown() {
			return nil, nil
		}
		underlying := v.UnderlyingValue()
		if underlying == nil {
			return nil, nil
		}
		return attrValueToAny(ctx, underlying)
	default:
		return nil, diag.Diagnostics{diag.NewErrorDiagnostic("Unsupported attribute type", val.Type(ctx).String())}
	}
}

func dropDynamicAttrs(schemaName string, input map[string]any) map[string]any {
	if input == nil {
		return input
	}
	typesMap := mustSchemaAttrTypes(schemaName)
	if len(typesMap) == 0 {
		return input
	}
	out := map[string]any{}
	for k, v := range input {
		if t, ok := typesMap[k]; ok {
			if t.Equal(types.DynamicType) {
				continue
			}
		}
		out[k] = v
	}
	return out
}

func objectFromMap(ctx context.Context, typesMap map[string]attr.Type, input map[string]any) (types.Object, diag.Diagnostics) {
	attrs := map[string]attr.Value{}
	var diags diag.Diagnostics
	for name, typ := range typesMap {
		val, ok := input[name]
		if !ok {
			attrs[name] = nullValueForType(typ)
			continue
		}
		av, vDiags := valueToAttr(ctx, typ, val)
		diags.Append(vDiags...)
		attrs[name] = av
	}
	obj, oDiags := types.ObjectValue(typesMap, attrs)
	diags.Append(oDiags...)
	return obj, diags
}

func valueToAttr(ctx context.Context, typ attr.Type, val any) (attr.Value, diag.Diagnostics) {
	if val == nil {
		return nullValueForType(typ), nil
	}
	switch t := typ.(type) {
	case basetypes.StringType:
		switch v := val.(type) {
		case string:
			return types.StringValue(v), nil
		default:
			return types.StringValue(fmt.Sprintf("%v", v)), nil
		}
	case basetypes.Int64Type:
		switch v := val.(type) {
		case int:
			return types.Int64Value(int64(v)), nil
		case int64:
			return types.Int64Value(v), nil
		case float64:
			return types.Int64Value(int64(v)), nil
		default:
			return types.Int64Null(), nil
		}
	case basetypes.Float64Type:
		switch v := val.(type) {
		case float64:
			return types.Float64Value(v), nil
		case float32:
			return types.Float64Value(float64(v)), nil
		case int:
			return types.Float64Value(float64(v)), nil
		case int64:
			return types.Float64Value(float64(v)), nil
		default:
			return types.Float64Null(), nil
		}
	case basetypes.BoolType:
		if v, ok := val.(bool); ok {
			return types.BoolValue(v), nil
		}
		return types.BoolNull(), nil
	case basetypes.ObjectType:
		m, ok := val.(map[string]any)
		if !ok {
			return types.ObjectNull(t.AttrTypes), nil
		}
		return objectFromMap(ctx, t.AttrTypes, m)
	case basetypes.ListType:
		slice, ok := val.([]any)
		if !ok {
			return types.ListNull(t.ElemType), nil
		}
		elems := make([]attr.Value, 0, len(slice))
		var diags diag.Diagnostics
		for _, item := range slice {
			ev, eDiags := valueToAttr(ctx, t.ElemType, item)
			diags.Append(eDiags...)
			elems = append(elems, ev)
		}
		list, lDiags := types.ListValue(t.ElemType, elems)
		diags.Append(lDiags...)
		return list, diags
	case basetypes.MapType:
		m, ok := val.(map[string]any)
		if !ok {
			return types.MapNull(t.ElemType), nil
		}
		elems := map[string]attr.Value{}
		var diags diag.Diagnostics
		for k, item := range m {
			ev, eDiags := valueToAttr(ctx, t.ElemType, item)
			diags.Append(eDiags...)
			elems[k] = ev
		}
		mv, mDiags := types.MapValue(t.ElemType, elems)
		diags.Append(mDiags...)
		return mv, diags
	case basetypes.DynamicType:
		return types.DynamicNull(), nil
	default:
		return types.DynamicNull(), nil
	}
}

func nullValueForType(typ attr.Type) attr.Value {
	switch t := typ.(type) {
	case basetypes.StringType:
		return types.StringNull()
	case basetypes.Int64Type:
		return types.Int64Null()
	case basetypes.Float64Type:
		return types.Float64Null()
	case basetypes.BoolType:
		return types.BoolNull()
	case basetypes.ObjectType:
		return types.ObjectNull(t.AttrTypes)
	case basetypes.ListType:
		return types.ListNull(t.ElemType)
	case basetypes.MapType:
		return types.MapNull(t.ElemType)
	case basetypes.DynamicType:
		return types.DynamicNull()
	default:
		return types.DynamicNull()
	}
}

func dynamicToObjectsWithSchema(ctx context.Context, dyn types.Dynamic, schemaName string) ([]map[string]any, diag.Diagnostics) {
	if dyn.IsNull() || dyn.IsUnknown() {
		return []map[string]any{}, nil
	}
	underlying := dyn.UnderlyingValue()
	if underlying == nil {
		return []map[string]any{}, nil
	}
	if list, ok := underlying.(types.List); ok {
		return listToObjectsWithSchema(ctx, list, schemaName)
	}
	return []map[string]any{}, diag.Diagnostics{diag.NewErrorDiagnostic("Invalid dynamic spec", "Expected a list value for dynamic spec")}
}

func transformTFToAPIMap(input map[string]any, meta *schemaFieldMeta) map[string]any {
	if meta == nil || meta.Kind != "object" {
		return input
	}
	out := map[string]any{}
	for tfName, v := range input {
		fieldMeta, ok := meta.Fields[tfName]
		if !ok || fieldMeta == nil {
			out[tfName] = v
			continue
		}
		apiName := fieldMeta.APIName
		if apiName == "" {
			apiName = tfName
		}
		out[apiName] = transformTFToAPIValue(v, fieldMeta)
	}
	return out
}

func transformTFToAPIValue(value any, meta *schemaFieldMeta) any {
	if meta == nil {
		return value
	}
	switch meta.Kind {
	case "object":
		m, ok := value.(map[string]any)
		if !ok {
			return value
		}
		return transformTFToAPIMap(m, meta)
	case "list":
		slice, ok := value.([]any)
		if !ok {
			return value
		}
		if meta.Elem == nil {
			return value
		}
		out := make([]any, 0, len(slice))
		for _, item := range slice {
			out = append(out, transformTFToAPIValue(item, meta.Elem))
		}
		return out
	case "map":
		m, ok := value.(map[string]any)
		if !ok {
			return value
		}
		if meta.Elem == nil {
			return value
		}
		out := map[string]any{}
		for k, v := range m {
			out[k] = transformTFToAPIValue(v, meta.Elem)
		}
		return out
	default:
		return value
	}
}

func transformAPIToTFMap(input map[string]any, meta *schemaFieldMeta) map[string]any {
	if meta == nil || meta.Kind != "object" {
		return input
	}
	apiToTF := map[string]string{}
	for tfName, fieldMeta := range meta.Fields {
		if fieldMeta == nil {
			continue
		}
		apiName := fieldMeta.APIName
		if apiName == "" {
			apiName = tfName
		}
		apiToTF[apiName] = tfName
	}

	out := map[string]any{}
	for apiName, v := range input {
		tfName, ok := apiToTF[apiName]
		if !ok {
			out[apiName] = v
			continue
		}
		fieldMeta := meta.Fields[tfName]
		out[tfName] = transformAPIToTFValue(v, fieldMeta)
	}
	return out
}

func transformAPIToTFValue(value any, meta *schemaFieldMeta) any {
	if meta == nil {
		return value
	}
	switch meta.Kind {
	case "object":
		m, ok := value.(map[string]any)
		if !ok {
			return value
		}
		return transformAPIToTFMap(m, meta)
	case "list":
		slice, ok := value.([]any)
		if !ok {
			return value
		}
		if meta.Elem == nil {
			return value
		}
		out := make([]any, 0, len(slice))
		for _, item := range slice {
			out = append(out, transformAPIToTFValue(item, meta.Elem))
		}
		return out
	case "map":
		m, ok := value.(map[string]any)
		if !ok {
			return value
		}
		if meta.Elem == nil {
			return value
		}
		out := map[string]any{}
		for k, v := range m {
			out[k] = transformAPIToTFValue(v, meta.Elem)
		}
		return out
	default:
		return value
	}
}

func dropKeysToTF(meta *schemaFieldMeta, dropKeys []string) []string {
	if meta == nil || meta.Kind != "object" || len(dropKeys) == 0 {
		return dropKeys
	}
	apiToTF := map[string]string{}
	for tfName, fieldMeta := range meta.Fields {
		if fieldMeta == nil {
			continue
		}
		apiName := fieldMeta.APIName
		if apiName == "" {
			apiName = tfName
		}
		apiToTF[apiName] = tfName
	}
	out := make([]string, 0, len(dropKeys))
	for _, key := range dropKeys {
		if tfName, ok := apiToTF[key]; ok {
			out = append(out, tfName)
		} else {
			out = append(out, key)
		}
	}
	return out
}
