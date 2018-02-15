###########################################

# Plik Dockerfile tworzący obraz Apache2.

###########################################

# Bazowy obraz to Ubuntu.

FROM ubuntu

# Autor: dr Peter.

MAINTAINER dr Peter <peterindia@gmail.com>

# Utwórz folder o nazwie nowyfolder i plik o nazwie nowyplik.

RUN mkdir nowyfolder

RUN touch /nowyfolder/nowyplik

# Umieść wiadomość w pliku.

RUN echo 'There is soul in it :)' > /nowyfolder/nowyplik
