package provider

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/resource"
)

func (p *haproxyProvider) Resources(ctx context.Context) []func() resource.Resource {
	return []func() resource.Resource{
		NewBackendResource,
		NewBindResource,
		NewFrontendResource,
		NewServerResource,
	}
}
