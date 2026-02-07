package provider

import (
	"context"
	"net/url"

	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/types"
	"github.com/pderuiter/terraform-provider-haproxy-dataplane/internal/client"
)

var _ resource.Resource = (*backendResource)(nil)

func NewBackendResource() resource.Resource {
	return &backendResource{}
}

type backendResource struct {
	client *client.Client
}

type backendModel struct {
	ID         types.String `tfsdk:"id"`
	Name       types.String `tfsdk:"name"`
	ConfigJSON types.String `tfsdk:"config_json"`
}

func (r *backendResource) Metadata(ctx context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_backend"
}

func (r *backendResource) Schema(ctx context.Context, req resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Description: "Manages HAProxy backend configuration via the Data Plane API.",
		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				Computed:    true,
				Description: "Backend name.",
			},
			"name": schema.StringAttribute{
				Required:    true,
				Description: "Backend name.",
			},
			"config_json": schema.StringAttribute{
				Required:    true,
				Description: "Backend configuration as JSON payload accepted by the Data Plane API.",
			},
		},
	}
}

func (r *backendResource) Configure(ctx context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
	client, diags := getClient(req.ProviderData)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}
	if client != nil {
		r.client = client
	}
}

func (r *backendResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var plan backendModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &plan)...)
	if resp.Diagnostics.HasError() {
		return
	}

	normalized, payload, err := normalizeJSON(plan.ConfigJSON.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("Invalid config_json", err.Error())
		return
	}
	payload["name"] = plan.Name.ValueString()

	version, err := getConfigVersion(ctx, r.client)
	if err != nil {
		resp.Diagnostics.AddError("Unable to read configuration version", err.Error())
		return
	}

	query := url.Values{"version": []string{int64ToString(version)}}
	if err := r.client.PostJSON(ctx, "/services/haproxy/configuration/backends", query, payload, nil); err != nil {
		resp.Diagnostics.AddError("Create backend failed", err.Error())
		return
	}

	plan.ID = plan.Name
	plan.ConfigJSON = types.StringValue(normalized)
	resp.Diagnostics.Append(resp.State.Set(ctx, &plan)...)
}

func (r *backendResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var state backendModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	if resp.Diagnostics.HasError() {
		return
	}

	var out map[string]any
	if err := r.client.GetJSON(ctx, "/services/haproxy/configuration/backends/"+state.Name.ValueString(), nil, &out); err != nil {
		if client.IsNotFound(err) {
			resp.State.RemoveResource(ctx)
			return
		}
		resp.Diagnostics.AddError("Read backend failed", err.Error())
		return
	}

	jsonStr, err := encodeJSON(out)
	if err != nil {
		resp.Diagnostics.AddError("Read backend failed", err.Error())
		return
	}

	state.ConfigJSON = types.StringValue(jsonStr)
	resp.Diagnostics.Append(resp.State.Set(ctx, &state)...)
}

func (r *backendResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var plan backendModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &plan)...)
	if resp.Diagnostics.HasError() {
		return
	}

	normalized, payload, err := normalizeJSON(plan.ConfigJSON.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("Invalid config_json", err.Error())
		return
	}
	payload["name"] = plan.Name.ValueString()

	version, err := getConfigVersion(ctx, r.client)
	if err != nil {
		resp.Diagnostics.AddError("Unable to read configuration version", err.Error())
		return
	}

	query := url.Values{"version": []string{int64ToString(version)}}
	if err := r.client.PutJSON(ctx, "/services/haproxy/configuration/backends/"+plan.Name.ValueString(), query, payload, nil); err != nil {
		resp.Diagnostics.AddError("Update backend failed", err.Error())
		return
	}

	plan.ID = plan.Name
	plan.ConfigJSON = types.StringValue(normalized)
	resp.Diagnostics.Append(resp.State.Set(ctx, &plan)...)
}

func (r *backendResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var state backendModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	if resp.Diagnostics.HasError() {
		return
	}

	version, err := getConfigVersion(ctx, r.client)
	if err != nil {
		resp.Diagnostics.AddError("Unable to read configuration version", err.Error())
		return
	}

	query := url.Values{"version": []string{int64ToString(version)}}
	if err := r.client.DeleteJSON(ctx, "/services/haproxy/configuration/backends/"+state.Name.ValueString(), query, nil); err != nil {
		if client.IsNotFound(err) {
			return
		}
		resp.Diagnostics.AddError("Delete backend failed", err.Error())
		return
	}
}

var _ resource.ResourceWithConfigure = (*backendResource)(nil)
