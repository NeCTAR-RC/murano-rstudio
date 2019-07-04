TARGET=au.org.nectar.RStudio
.PHONY: $(TARGET).zip

all: $(TARGET).zip

build: $(TARGET).zip

clean:
	rm -rf $(TARGET).zip

upload: $(TARGET).zip
	murano package-import -c "Big Data" --package-version 1.0 --exists-action u $(TARGET).zip

public:
	@echo "Searching for $(TARGET) package ID..."
	@package_id=$$(murano package-list --fqn $(TARGET) | grep $(TARGET) | awk '{print $$2}'); \
	echo "Found ID: $$package_id"; \
	murano package-update --is-public true $$package_id

update-image-id:
	@echo "Searching for latest image of NeCTAR R-Studio (Ubuntu 18.04 LTS)..."
	@image_id=$$(openstack image show -f value -c id "NeCTAR R-Studio (Ubuntu 18.04 LTS)"); \
	if [ -z "$$image_id" ]; then \
		echo "Image ID not found"; exit 1; \
	fi; \
	echo "Found ID: $$image_id"; \
    eval $$(openstack image show $$image_id -f value -c properties); \
    sed -i "s/image:.*/image: $$image_id/g" $(TARGET)/UI/ui.yaml

$(TARGET).zip:
	rm -f $@; cd $(TARGET); zip ../$@ -r *; cd ..
