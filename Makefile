.SILENT: 

release:
	mkdir -p build
	echo ""

	for XRNX in *.xrnx; do \
		if [ ! -d $$XRNX ]; then continue; fi; \
		echo $$XRNX:; \
		sh -c "cd $$XRNX && zip ../build/$$XRNX ./*"; \
		echo ""; \
	done
