TARGET=au.org.nectar.RStudio
.PHONY: package.zip

all: package.zip

build: package.zip

clean:
	rm -rf package.zip

upload: package.zip
	murano package-import -c "Big Data" --package-version 1.0 --exists-action u package.zip

check: package.zip
	murano-pkg-check --ignore W011 package.zip

public:
	@echo "Searching for $(TARGET) package ID..."
	@package_id=$$(murano package-list --fqn $(TARGET) | grep $(TARGET) | awk '{print $$2}'); \
	echo "Found ID: $$package_id"; \
	murano package-update --is-public true $$package_id

update-image-id:
	@echo "Searching for latest image of NeCTAR R-Studio (Ubuntu 20.04 LTS Focal)..."
	@image_id=$$(openstack image show -f value -c id "NeCTAR R-Studio (Ubuntu 20.04 LTS Focal)"); \
	if [ -z "$$image_id" ]; then \
		echo "Image ID not found"; exit 1; \
	fi; \
	echo "Found ID: $$image_id"; \
    sed -i "s/image:.*/image: $$image_id/g" $(TARGET)/UI/ui.yaml

package.zip:
	rm -f $@; cd $(TARGET); zip ../$@ -r *; cd ..
