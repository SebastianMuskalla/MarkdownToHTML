FROM ubuntu
RUN apt-get update && apt-get install -y \
    curl \
    jq
COPY markdownToHTML.sh /script/
COPY templates/* /script/templates/
COPY css/*.css /script/css/
ENTRYPOINT ["/script/markdownToHTML.sh"]
