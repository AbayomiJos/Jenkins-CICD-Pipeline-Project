FROM tomcat
RUN rm -rvf /usr/local/tomcat/webapps
RUN mv /usr/local/tomcat/webapps.dist /usr/local/tomcat/webapps
COPY student.war /usr/local/tomcat/webapps/
CMD /usr/local/tomcat/bin/startup.sh; sleep inf
