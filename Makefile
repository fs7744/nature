
N_EXEC ?= $(shell which openresty)
LUAROCKS ?= luarocks
OR_PREFIX ?= $(shell $(N_EXEC) -V 2>&1 | grep -Eo 'prefix=(.*)/nginx\s+' | grep -Eo '/.*/')
OPENSSL_PREFIX ?= $(addprefix $(OR_PREFIX), openssl111)
LUAROCKS_SERVER_OPT =
ifneq ($(LUAROCKS_SERVER), )
	LUAROCKS_SERVER_OPT = --server ${LUAROCKS_SERVER}
endif
INSTALL ?= install

default:
	mkdir -p logs && mkdir -p tmp
ifeq ($(N_EXEC), )
	@echo "OpenResty not found !"
	exit 1
endif

dev-deps: default
	@for rock in $(DEV_ROCKS) ; do \
	  if luarocks list --porcelain $$rock | grep -q "installed" ; then \
	    echo $$rock already installed, skipping ; \
	  else \
	    echo $$rock not found, installing via luarocks... ; \
	    luarocks install $$rock OPENSSL_DIR=$(OPENSSL_DIR) CRYPTO_DIR=$(OPENSSL_DIR); \
	  fi \
	done;

deps: dev-deps
ifeq ($(shell whoami),root)
	$(LUAROCKS) config variables.OPENSSL_LIBDIR $(addprefix $(OPENSSL_PREFIX), /lib)
	$(LUAROCKS) config variables.OPENSSL_INCDIR $(addprefix $(OPENSSL_PREFIX), /include)
else
	$(LUAROCKS) config --local variables.OPENSSL_LIBDIR $(addprefix $(OPENSSL_PREFIX), /lib)
	$(LUAROCKS) config --local variables.OPENSSL_INCDIR $(addprefix $(OPENSSL_PREFIX), /include)
endif
	$(LUAROCKS) install rockspec/nature-main-0.rockspec --tree=deps --only-deps --local $(LUAROCKS_SERVER_OPT)


test: default
	prove -I../test-nginx/lib -I./ -r -s t/

dev: default
	$(N_EXEC) -p $(shell pwd) -c conf/nginx.conf -g 'daemon off;'

reload: default
	$(N_EXEC) -p $(shell pwd) -c conf/nginx.conf -s reload

stop: default
	$(N_EXEC) -p $(shell pwd) -c conf/nginx.conf -s stop

etcd: default
	docker run -p 2479:2479 -p 2480:2480 --mount type=bind,source=$(shell pwd)/tmp/etcd-data.tmp,destination=/etcd-data --name etcd \
	gcr.io/etcd-development/etcd:v3.5.0 \
	/usr/local/bin/etcd \
	--name s1 \
	--data-dir /etcd-data \
	--listen-client-urls http://0.0.0.0:2479 \
	--advertise-client-urls http://0.0.0.0:2479 \
	--listen-peer-urls http://0.0.0.0:2480 \
	--initial-advertise-peer-urls http://0.0.0.0:2480 \
	--initial-cluster s1=http://0.0.0.0:2480 \
	--initial-cluster-token tkn \
	--initial-cluster-state new \
	--log-level info \
	--logger zap \
	--log-outputs stderr

install:
	$(INSTALL) -d $(INST_LUADIR)/nature
	$(INSTALL) nature/*.lua $(INST_LUADIR)/nature/

	$(INSTALL) -d $(INST_LUADIR)/nature/cli
	$(INSTALL) nature/cli/*.lua $(INST_LUADIR)/nature/cli/
	
#publish:
#	luarocks upload rockspec/nature-0.0.1-0.rockspec --skip-pack --api-key=