package provider

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/resource"
)

func (p *haproxyProvider) Resources(ctx context.Context) []func() resource.Resource {
	resources := generatedResources()
	resources = append(resources, generatedRuntimeResources()...)
	return resources
}
