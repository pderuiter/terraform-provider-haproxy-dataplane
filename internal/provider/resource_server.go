package provider

import (
	"context"
	"net/url"

	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/types"
	"github.com/pderuiter/terraform-provider-haproxy-dataplane/internal/client"
)

var _ resource.Resource = (*serverResource)(nil)

func NewServerResource() resource.Resource {
	return &serverResource{}
}

type serverResource struct {
	client *client.Client
}

type serverModel struct {
	ID         types.String `tfsdk:"id"`
	Backend    types.String `tfsdk:"backend"`
	Name       types.String `tfsdk:"name"`
	ConfigJSON types.String `tfsdk:"config_json"`
}

func (r *serverResource) Metadata(ctx context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_server"
}

func (r *serverResource) Schema(ctx context.Context, req resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Description: "Manages HAProxy backend server configuration via the Data Plane API.",
		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				Computed:    true,
				Description: "Server id (backend/name).",
			},
			"backend": schema.StringAttribute{
				Required:    true,
				Description: "Backend name that owns the server.",
			},
			"name": schema.StringAttribute{
				Required:    true,
				Description: "Server name.",
			},
			"config_json": schema.StringAttribute{
				Required:    true,
				Description: "Server configuration as JSON payload accepted by the Data Plane API.",
			},
		},
	}
}

func (r *serverResource) Configure(ctx context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
	client, diags := getClient(req.ProviderData)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}
	if client != nil {
		r.client = client
	}
}

func (r *serverResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var plan serverModel
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

	query := url.Values{
		"backend": []string{plan.Backend.ValueString()},
		"version": []string{int64ToString(version)},
	}
	if err := r.client.PostJSON(ctx, "/services/haproxy/configuration/servers", query, payload, nil); err != nil {
		resp.Diagnostics.AddError("Create server failed", err.Error())
		return
	}

	plan.ID = types.StringValue(plan.Backend.ValueString() + "/" + plan.Name.ValueString())
	plan.ConfigJSON = types.StringValue(normalized)
	resp.Diagnostics.Append(resp.State.Set(ctx, &plan)...)
}

func (r *serverResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var state serverModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	if resp.Diagnostics.HasError() {
		return
	}

	query := url.Values{"backend": []string{state.Backend.ValueString()}}
	var out map[string]any
	if err := r.client.GetJSON(ctx, "/services/haproxy/configuration/servers/"+state.Name.ValueString(), query, &out); err != nil {
		if client.IsNotFound(err) {
			resp.State.RemoveResource(ctx)
			return
		}
		resp.Diagnostics.AddError("Read server failed", err.Error())
		return
	}

	jsonStr, err := encodeJSON(out)
	if err != nil {
		resp.Diagnostics.AddError("Read server failed", err.Error())
		return
	}

	state.ConfigJSON = types.StringValue(jsonStr)
	resp.Diagnostics.Append(resp.State.Set(ctx, &state)...)
}

func (r *serverResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var plan serverModel
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

	query := url.Values{
		"backend": []string{plan.Backend.ValueString()},
		"version": []string{int64ToString(version)},
	}
	if err := r.client.PutJSON(ctx, "/services/haproxy/configuration/servers/"+plan.Name.ValueString(), query, payload, nil); err != nil {
		resp.Diagnostics.AddError("Update server failed", err.Error())
		return
	}

	plan.ID = types.StringValue(plan.Backend.ValueString() + "/" + plan.Name.ValueString())
	plan.ConfigJSON = types.StringValue(normalized)
	resp.Diagnostics.Append(resp.State.Set(ctx, &plan)...)
}

func (r *serverResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var state serverModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	if resp.Diagnostics.HasError() {
		return
	}

	version, err := getConfigVersion(ctx, r.client)
	if err != nil {
		resp.Diagnostics.AddError("Unable to read configuration version", err.Error())
		return
	}

	query := url.Values{
		"backend": []string{state.Backend.ValueString()},
		"version": []string{int64ToString(version)},
	}
	if err := r.client.DeleteJSON(ctx, "/services/haproxy/configuration/servers/"+state.Name.ValueString(), query, nil); err != nil {
		if client.IsNotFound(err) {
			return
		}
		resp.Diagnostics.AddError("Delete server failed", err.Error())
		return
	}
}

var _ resource.ResourceWithConfigure = (*serverResource)(nil)
