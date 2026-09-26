import arsd.cgi;

mixin DispatcherMain!("/".serveStaticFileDirectory("./", recursive: true));
