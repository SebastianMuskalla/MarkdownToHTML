FROM ubuntu

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    jq

COPY markdownToHTML.sh /script/
COPY templates/* /script/templates/
COPY css/*.css /script/css/

RUN chmod +x /script/markdownToHTML.sh

ENTRYPOINT ["/script/markdownToHTML.sh"]
