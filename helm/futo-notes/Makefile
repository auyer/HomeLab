SHELL := /bin/bash
NAMESPACE ?= futo-notes

upgrade:
	helm upgrade --install -n futo-notes futo-notes . --create-namespace

uninstall:
	helm uninstall -n futo-notes futo-notes

# Creates templates/sealed-futo-notes.yaml.
# Use a URL-safe POSTGRES_PASSWORD (e.g. `openssl rand -hex 32`), since it is
# embedded in the generated DATABASE_URL. DATABASE_URL points at the built-in
# Postgres (futo-notes-postgres); override it if you connect to an external DB.
secrets/create:
	@echo "Enter POSTGRES_PASSWORD (hint: openssl rand -hex 32):" && read -s PGPASS && echo && \
	echo "Enter FUTO_NOTES_PASSWORD:" && read -s NOTESPASS && echo && \
	kubectl create secret generic futo-notes-secrets \
		-n $(NAMESPACE) \
		--from-literal=POSTGRES_PASSWORD=$$PGPASS \
		--from-literal=DATABASE_URL="postgres://futo_notes:$$PGPASS@futo-notes-postgres:5432/futo_notes" \
		--from-literal=FUTO_NOTES_PASSWORD=$$NOTESPASS \
		--dry-run=client -o yaml | \
	kubeseal --format yaml -o yaml > templates/sealed-futo-notes.yaml && \
	echo "Created templates/sealed-futo-notes.yaml"

