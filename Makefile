.DEFAULT_GOAL := generate_templates

generate_templates:
	scripts/generate_ui_templates.sh

dummy_data: generate_templates
	scripts/dummy_data.sh

hashicups:
	scripts/hashicups.sh

dev:
	scripts/dev.sh

clean:
	rm -rf examples/existing-vpc/output.json
