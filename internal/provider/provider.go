package provider

import (
	"context"
	"fmt"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/provider"
	"github.com/hashicorp/terraform-plugin-framework/provider/schema"
	"github.com/hashicorp/terraform-plugin-framework/types"
	"github.com/pderuiter/terraform-provider-haproxy-dataplane/internal/client"
)

var _ provider.Provider = (*haproxyProvider)(nil)

func New(version string) func() provider.Provider {
	return func() provider.Provider {
		return &haproxyProvider{version: version}
	}
}

type haproxyProvider struct {
	version string
}

const providerTypeName = "haproxy-dataplane"

type providerConfig struct {
	Endpoint       types.String `tfsdk:"endpoint"`
	APIPath        types.String `tfsdk:"api_path"`
	Username       types.String `tfsdk:"username"`
	Password       types.String `tfsdk:"password"`
	Token          types.String `tfsdk:"token"`
	CACertPEM      types.String `tfsdk:"ca_cert_pem"`
	ClientCertPEM  types.String `tfsdk:"client_cert_pem"`
	ClientKeyPEM   types.String `tfsdk:"client_key_pem"`
	Insecure       types.Bool   `tfsdk:"insecure"`
	TimeoutSeconds types.Int64  `tfsdk:"timeout_seconds"`
}

func (p *haproxyProvider) Metadata(ctx context.Context, req provider.MetadataRequest, resp *provider.MetadataResponse) {
	resp.TypeName = providerTypeName
	resp.Version = p.version
}

func (p *haproxyProvider) Schema(ctx context.Context, req provider.SchemaRequest, resp *provider.SchemaResponse) {
	resp.Schema = schema.Schema{
		Description: "Terraform provider for HAProxy Data Plane API.",
		Attributes: map[string]schema.Attribute{
			"endpoint": schema.StringAttribute{
				Description: "Base URL for the HAProxy Data Plane API, for example https://haproxy.example.com:5555.",
				Required:    true,
			},
			"api_path": schema.StringAttribute{
				Description: "Base API path for the Data Plane API, for example /v3. Defaults to /v3.",
				Optional:    true,
			},
			"username": schema.StringAttribute{
				Description: "Username for basic auth. Use with password if token is not provided.",
				Optional:    true,
			},
			"password": schema.StringAttribute{
				Description: "Password for basic auth. Use with username if token is not provided.",
				Optional:    true,
				Sensitive:   true,
			},
			"token": schema.StringAttribute{
				Description: "Bearer token for the Data Plane API.",
				Optional:    true,
				Sensitive:   true,
			},
			"ca_cert_pem": schema.StringAttribute{
				Description: "PEM-encoded CA certificate to trust for TLS.",
				Optional:    true,
				Sensitive:   true,
			},
			"client_cert_pem": schema.StringAttribute{
				Description: "PEM-encoded client certificate for mTLS.",
				Optional:    true,
				Sensitive:   true,
			},
			"client_key_pem": schema.StringAttribute{
				Description: "PEM-encoded client private key for mTLS.",
				Optional:    true,
				Sensitive:   true,
			},
			"insecure": schema.BoolAttribute{
				Description: "Skip TLS certificate verification.",
				Optional:    true,
			},
			"timeout_seconds": schema.Int64Attribute{
				Description: "HTTP client timeout in seconds.",
				Optional:    true,
			},
		},
	}
}

func (p *haproxyProvider) Configure(ctx context.Context, req provider.ConfigureRequest, resp *provider.ConfigureResponse) {
	var config providerConfig

	diags := req.Config.Get(ctx, &config)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	clientCfg := client.Config{
		Endpoint:       config.Endpoint.ValueString(),
		APIPrefix:      config.APIPath.ValueString(),
		Username:       config.Username.ValueString(),
		Password:       config.Password.ValueString(),
		Token:          config.Token.ValueString(),
		CACertPEM:      config.CACertPEM.ValueString(),
		ClientCertPEM:  config.ClientCertPEM.ValueString(),
		ClientKeyPEM:   config.ClientKeyPEM.ValueString(),
		Insecure:       config.Insecure.ValueBool(),
		TimeoutSeconds: config.TimeoutSeconds.ValueInt64(),
	}

	hclient, err := client.New(clientCfg)
	if err != nil {
		resp.Diagnostics.AddError("Unable to create HAProxy client", fmt.Sprintf("%v", err))
		return
	}

	resp.DataSourceData = hclient
	resp.ResourceData = hclient
}

func (p *haproxyProvider) DataSources(ctx context.Context) []func() datasource.DataSource {
	return append(generatedDataSources(), generatedRuntimeDataSources()...)
}
