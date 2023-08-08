PORTNAME=	spacevm-sendfio
DISTVERSION=	0.1
CATEGORIES=	sysutils

MAINTAINER=	olevole@olevole.ru
COMMENT=	SpaceVM sendfio stats
WWW=		https://spacevm.ru

LICENSE=	BSD2CLAUSE
LICENSE_FILE=	${WRKSRC}/LICENSE

RUN_DEPENDS=	curl:ftp/curl \
		fio:benchmarks/fio

#USES=		compiler:c++11-lang libedit pkgconfig:both
USE_GITHUB=	yes
GH_ACCOUNT=	mergar
GH_PROJECT=	send-fio
GH_TAGNAME=	64b46fd

SUB_FILES=	pkg-message

do-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/share/spacevm
	${CP} -a ${WRKSRC}/bin/spacevm-perf-fio-fioloop ${STAGEDIR}${PREFIX}/bin/
	${CP} -a ${WRKSRC}/bin/spacevm-perf-fio-run ${STAGEDIR}${PREFIX}/bin/
	${CP} -a ${WRKSRC}/bin/spacevm-perf-fio-send ${STAGEDIR}${PREFIX}/bin/
	${CP} -a ${WRKSRC}/bin/spacevm-select-item ${STAGEDIR}${PREFIX}/bin/
	#${CP} -a ${WRKSRC}/share/fio ${STAGEDIR}${PREFIX}/share/spacevm/
	${CP} -a ${WRKSRC}/share/fio-scripts ${STAGEDIR}${PREFIX}/share/spacevm/
	${CP} -a ${WRKSRC}/share/fio-subr ${STAGEDIR}${PREFIX}/share/spacevm/
	${INSTALL_DATA} ${WRKSRC}/etc/spacevm-perf-fio.conf \
		${STAGEDIR}${PREFIX}/etc/spacevm-perf-fio.conf.sample

.include <bsd.port.mk>
