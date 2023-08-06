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
GH_TAGNAME=	8803e89

SUB_FILES=	pkg-message

.include <bsd.port.mk>
