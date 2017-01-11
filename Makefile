TARGET=au.org.nectar.RStudio
.PHONY: $(TARGET).zip

all: update-image-id $(TARGET).zip upload

build: $(TARGET).zip

clean:
	rm -rf $(TARGET).zip

upload: $(TARGET).zip
	murano package-import -c "Big Data" --package-version 1.0 --exists-action u $(TARGET).zip

update-image-id:
	@echo "Searching for latest image of NeCTAR R-Studio (Ubuntu 16.04 LTS Xenial)..."
	@image_id=$$(openstack image list --limit 100 --long -f value -c ID -c Project --property "name=NeCTAR R-Studio (Ubuntu 16.04 LTS Xenial)" --sort created_at | tail -n1 | cut -d" " -f1); \
	echo "Found ID: $$image_id"; \
	sed -i "s/image:.*/image: $$image_id/g" $(TARGET)/UI/ui.yaml

$(TARGET).zip:
	rm -f $@; cd $(TARGET); zip ../$@ -r *; cd ..
