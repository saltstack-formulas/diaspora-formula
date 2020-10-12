# Changelog

# 1.0.0 (2020-10-12)


### Bug Fixes

* **centos:** enable powertools repo for libidn-devel on centos 8 ([95e2336](https://github.com/SuperTux88/diaspora-formula/commit/95e2336d814dcbc286d3a74854cf47c32eafe755))
* **centos:** fix dependencies for centos ([8203e6c](https://github.com/SuperTux88/diaspora-formula/commit/8203e6c73523d01cfec32d027dc6b790ead1e77d))
* **dependencies:** tzdata is required for precompile ([527691b](https://github.com/SuperTux88/diaspora-formula/commit/527691be88d9cd85132e02e44098962d28e5b44f))
* **mysql:** fix check if db exists for mysql ([be7281b](https://github.com/SuperTux88/diaspora-formula/commit/be7281b97c4a810fcb95ed88ee1e783d1b157a23))
* **service:** don't reload too quick after starting the service ([49a5a42](https://github.com/SuperTux88/diaspora-formula/commit/49a5a42ff917d73f6f06c2c135785955151be87e))


### Code Refactoring

* **dependencies:** remove some dependencies from debian and ubuntu ([63628a4](https://github.com/SuperTux88/diaspora-formula/commit/63628a4d92d8bc44e93b21f699fefd1472640773))
* **maps:** refactor map.jinja based on template-formula ([716e751](https://github.com/SuperTux88/diaspora-formula/commit/716e7516295b762d5c139519e4e08bc116c155ce))
* **redis:** move redis_service to service.sls ([a8d08ff](https://github.com/SuperTux88/diaspora-formula/commit/a8d08ff1eb344fa8fa57a9a452c54142cb0b1dd9))
* **yaml:** fix yamllint errors, update pillar for tests ([5798ac1](https://github.com/SuperTux88/diaspora-formula/commit/5798ac12bdf154f769bb039736f77ead686ff8fd))


### Continuous Integration

* **centos:** switch centos away from tiamat builds too ([084a815](https://github.com/SuperTux88/diaspora-formula/commit/084a815a78ce28ae8b18b21a8ba0c5a4648efa07))
* **travis:** reduce number of travis jobs ([a2f9554](https://github.com/SuperTux88/diaspora-formula/commit/a2f955423cbd57d3c6aec3a32bc9cc1631f2825c))


### Features

* **arch:** add support for archlinux ([7571d3d](https://github.com/SuperTux88/diaspora-formula/commit/7571d3d5772511a46529a5fab646dddc813aa7d5))
* **semantic-release:** add files base files from template-formula ([f45790a](https://github.com/SuperTux88/diaspora-formula/commit/f45790a4bcd981b9d71ca3ce55ba2947e4050d0e))


### Styles

* **salt-lint:** fix salt-lint errors in install.sls ([f19316b](https://github.com/SuperTux88/diaspora-formula/commit/f19316bc5f3be405bad043adb6718abf988e5941))


### Tests

* **mysql:** add tests with mysql ([ba0e4fa](https://github.com/SuperTux88/diaspora-formula/commit/ba0e4fafb3840ccc7b367b3a9c6f13da232ffd11))
* add some more tests to see if diaspora is working ([2690d37](https://github.com/SuperTux88/diaspora-formula/commit/2690d370ea7aa8e74c8a2a3d7f1cebc8b8c514ca))
* **postgres:** install postgres for tests ([c2b6e43](https://github.com/SuperTux88/diaspora-formula/commit/c2b6e4314f60fea5c6566583a5471f8dbad875ec))
* **ubuntu-1804:** fix ipv6 bind problem on ubuntu 18.04 in docker ([07346a1](https://github.com/SuperTux88/diaspora-formula/commit/07346a13fb732d2cd656cf60b5f1cfb26a0acfb6))
