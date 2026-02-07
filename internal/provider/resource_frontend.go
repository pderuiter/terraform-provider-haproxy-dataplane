package provider

import (
	"context"
	"net/url"

	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/types"
	"github.com/pderuiter/terraform-provider-haproxy-dataplane/internal/client"
)

var _ resource.Resource = (*frontendResource)(nil)

func NewFrontendResource() resource.Resource {
	return &frontendResource{}
}

type frontendResource struct {
	client *client.Client
}

type frontendModel struct {
	ID         types.String `tfsdk:"id"`
	Name       types.String `tfsdk:"name"`
	ConfigJSON types.String `tfsdk:"config_json"`
}

func (r *frontendResource) Metadata(ctx context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_frontend"
}

func (r *frontendResource) Schema(ctx context.Context, req resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Description: "Manages HAProxy frontend configuration via the Data Plane API.",
		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				Computed:    true,
				Description: "Frontend name.",
			},
			"name": schema.StringAttribute{
				Required:    true,
				Description: "Frontend name.",
			},
			"config_json": schema.StringAttribute{
				Required:    true,
				Description: "Frontend configuration as JSON payload accepted by the Data Plane API.",
			},
		},
	}
}

func (r *frontendResource) Configure(ctx context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
	client, diags := getClient(req.ProviderData)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}
	if client != nil {
		r.client = client
	}
}

func (r *frontendResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var plan frontendModel
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
	if err := r.client.PostJSON(ctx, "/services/haproxy/configuration/frontends", query, payload, nil); err != nil {
		resp.Diagnostics.AddError("Create frontend failed", err.Error())
		return
	}

	plan.ID = plan.Name
	plan.ConfigJSON = types.StringValue(normalized)
	resp.Diagnostics.Append(resp.State.Set(ctx, &plan)...)
}

func (r *frontendResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var state frontendModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	if resp.Diagnostics.HasError() {
		return
	}

	var out map[string]any
	if err := r.client.GetJSON(ctx, "/services/haproxy/configuration/frontends/"+state.Name.ValueString(), nil, &out); err != nil {
		if client.IsNotFound(err) {
			resp.State.RemoveResource(ctx)
			return
		}
		resp.Diagnostics.AddError("Read frontend failed", err.Error())
		return
	}

	jsonStr, err := encodeJSON(out)
	if err != nil {
		resp.Diagnostics.AddError("Read frontend failed", err.Error())
		return
	}

	state.ConfigJSON = types.StringValue(jsonStr)
	resp.Diagnostics.Append(resp.State.Set(ctx, &state)...)
}

func (r *frontendResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var plan frontendModel
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
	if err := r.client.PutJSON(ctx, "/services/haproxy/configuration/frontends/"+plan.Name.ValueString(), query, payload, nil); err != nil {
		resp.Diagnostics.AddError("Update frontend failed", err.Error())
		return
	}

	plan.ID = plan.Name
	plan.ConfigJSON = types.StringValue(normalized)
	resp.Diagnostics.Append(resp.State.Set(ctx, &plan)...)
}

func (r *frontendResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var state frontendModel
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
	if err := r.client.DeleteJSON(ctx, "/services/haproxy/configuration/frontends/"+state.Name.ValueString(), query, nil); err != nil {
		if client.IsNotFound(err) {
			return
		}
		resp.Diagnostics.AddError("Delete frontend failed", err.Error())
		return
	}
}

var _ resource.ResourceWithConfigure = (*frontendResource)(nil)
