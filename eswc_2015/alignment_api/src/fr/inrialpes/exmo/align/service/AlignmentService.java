/*
 * $Id: AlignmentService.java 1871 2014-01-16 20:25:53Z euzenat $
 *
 * Copyright (C) INRIA, 2006-2009, 2010, 2013-2014
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * as published by the Free Software Foundation; either version 2.1
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

package fr.inrialpes.exmo.align.service;

import fr.inrialpes.exmo.queryprocessor.QueryProcessor;
import fr.inrialpes.exmo.queryprocessor.Result;
import fr.inrialpes.exmo.queryprocessor.Type;

import fr.inrialpes.exmo.align.cli.CommonCLI;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.OptionBuilder;
import org.apache.commons.cli.ParseException;

import java.util.Hashtable;
import java.util.Enumeration;
import java.util.Properties;
import java.io.PrintStream;
import java.io.File;

import java.lang.reflect.InvocationTargetException;

/**
 * AlignmentService
 * 
 * The basic alignment service able to run a store and answer queries...
 * 
    <pre>
    java -jar alignsvc.jar [options]
    </pre>

    where the options are:
    <pre>
        --load=filename -l filename     Load previous image
	--params=filename -p filename   Read the parameters in file
        --help -h                       Print this message
    </pre>

<pre>
$Id: AlignmentService.java 1871 2014-01-16 20:25:53Z euzenat $
</pre>

 * @author J�r�me Euzenat
 */
public class AlignmentService extends CommonCLI {
    final static Logger logger = LoggerFactory.getLogger( AlignmentService.class );

    public String //DBMS Parameters
	DBHOST = "localhost",
	DBPORT = null,
	DBUSER = "adminAServ",
	DBPASS = "aaa345",
	DBBASE = "AServDB",
	DBMS   = "mysql";

    public static final String //Port Strings
	HTML = "8089",
	JADE = "8888",
	WSDL = "7777",
	JXTA = "6666";

    public static final String //IP Strings
	HOST = "localhost";

    private String filename = null;
    private String outfile = null;
    private String paramfile = null;
    private Hashtable<String,AlignmentServiceProfile> services = null;
    private Hashtable<String,Directory> directories = null;

    private AServProtocolManager manager;
    private DBService connection;

    public AlignmentService() {
	super();
	//options.addOption( OptionBuilder.withLongOpt( "load" ).hasArg().withDescription( "Load previous database image from FILE" ).withArgName("FILE").create( 'l' ) );
	options.addOption( OptionBuilder.withLongOpt( "impl" ).hasArg().withDescription( "Launch service corresponding to CLASS" ).withArgName("CLASS").create( 'i' ) );
	options.addOption( OptionBuilder.withLongOpt( "uriprefix" ).hasArg().withDescription( "Set alignment URIs with prefix URI" ).withArgName("URI").create( 'u' ) );
	options.addOption( OptionBuilder.withLongOpt( "host" ).hasArg().withDescription( "Set the HOSTNAME of the server" ).withArgName("HOSTNAME").create( 'S' ) );

	options.addOption( OptionBuilder.withLongOpt( "http" ).hasOptionalArg().withDescription( "Launch HTTP service (with port PORT; default "+HTML+")" ).withArgName("PORT").create( 'H' ) );
	options.addOption( OptionBuilder.withLongOpt( "jade" ).hasOptionalArg().withDescription( "Launch JADE service (with port PORT; default "+JADE+")" ).withArgName("PORT").create( 'A' ) );
	options.addOption( OptionBuilder.withLongOpt( "wsdl" ).hasOptionalArg().withDescription( "Launch Web service (with port PORT; default "+WSDL+")" ).withArgName("PORT").create( 'W' ) );
	options.addOption( OptionBuilder.withLongOpt( "jxta" ).hasOptionalArg().withDescription( "Launch JXTA service (with port PORT; default "+JXTA+")" ).withArgName("PORT").create( 'X' ) );

	options.addOption( "O", "oyster", false, "Register to Oyster directory" );
	//options.addOption( "U", "uddi", false, "Register to Oyster directory" );
	//options.addOption( OptionBuilder.withLongOpt( "params" ).hasArg().withDescription( "Read parameters from FILE" ).withArgName("FILE").create( 'p' ) );

	options.addOption( OptionBuilder.withLongOpt( "dbms" ).hasArg().withDescription( "Use DBMS system (mysql,postgres; default: mysql)" ).withArgName("DBMS").create( 'B' ) );
	options.addOption( OptionBuilder.withLongOpt( "dbmshost" ).hasArg().withDescription( "Use DBMS HOST (default: "+DBHOST+")" ).withArgName("HOST").create( 'm' ) );
	options.addOption( OptionBuilder.withLongOpt( "dbmsport" ).hasArg().withDescription( "Use DBMS PORT (default: "+DBPORT+")" ).withArgName("PORT").create( 's' ) );
	options.addOption( OptionBuilder.withLongOpt( "dbmsuser" ).hasArg().withDescription( "Use DBMS USER (default: scott)" ).withArgName("USER").create( 'l' ) );
	options.addOption( OptionBuilder.withLongOpt( "dbmspass" ).hasArg().withDescription( "Use DBMS PASSword (default: tiger)" ).withArgName("PASS").create( 'p' ) );
	options.addOption( OptionBuilder.withLongOpt( "dbmsbase" ).hasArg().withDescription( "Use DBMS BASE (default: "+DBBASE+")" ).withArgName("BASE").create( 'b' ) );

    }

    public static void main(String[] args) {
	try { new AlignmentService().run( args ); }
	catch ( Exception ex ) { logger.error( "FATAL error", ex ); };
    }
    
    public void run(String[] args) throws Exception {
	services = new Hashtable<String,AlignmentServiceProfile>();
	directories = new Hashtable<String,Directory>();

	// Read parameters
	readParameters( args );

	// In principle, this is useless
	if ( outputfilename != null ) {
	    // This redirects error outout to log file given by -o
	    System.setErr( new PrintStream( outputfilename ) );
	}

	logger.debug("Parameter parsed");

	// Shut down hook
	Runtime.getRuntime().addShutdownHook(new Thread(){
		public void run() { close(); } });

	// Connect database
	if ( DBMS.equals("postgres") ) {
	    logger.debug("postgres driver");
	    if ( DBPORT == null ) DBPORT = "5432";
	    connection = new DBServiceImpl( "org.postgresql.Driver",  "jdbc:postgresql", DBPORT );
	} else if ( DBMS.equals("mysql") ) {
	    logger.debug("mysql driver");
	    if ( DBPORT == null ) DBPORT = "3306";
	    connection = new DBServiceImpl( "com.mysql.jdbc.Driver",  "jdbc:mysql", DBPORT );
	} else {
	    logger.error( "Unsupported JDBC driver: {}", DBMS );
	    usage();
	    System.exit(-1);
	}
	try {
	    logger.debug("Connecting to database");
	    connection.init();
	    connection.connect( DBHOST, DBPORT, DBUSER, DBPASS, DBBASE );
	} catch ( Exception ex ) {
	    logger.error( ex.getMessage() );
	    System.exit(-1);
	}

	logger.debug("Database connected");

	// Create a AServProtocolManager
	manager = new AServProtocolManager( directories );
	manager.init( connection, parameters );
	logger.debug("Manager created");

	// Launch services
	for ( AlignmentServiceProfile serv : services.values() ) {
	    try {
		serv.init( parameters, manager );
	    } catch ( AServException ex ) { // This should rather be the job of the caller
		logger.warn( "Cannot start {} server on {}:{}", serv, parameters.getProperty( "host" ), parameters.getProperty( "http" ) );
	    }
	}
	logger.debug("Services launched");

	// Register to directories
	for ( Directory dir : directories.values() ) {
	    try {
		dir.open( parameters );
		logger.debug("{} connected.", dir);
	    } catch ( AServException ex ) {
		logger.warn( "Cannot connect to {} directory", dir );
		logger.debug( "IGNORED Connection exception", ex );
		// JE: this has to be done
		//directories.remove( name, dir );
	    }
	}
	logger.debug("Directories registered");

	// Wait loop
	logger.info("Alignment server running");
	while ( true ) {
	    // do not exhaust CPU
	    Thread.sleep(1000);
	}
    }

    protected void close(){
	logger.debug("Shuting down server");
	// [Directory]: unregister to directories
	for ( Directory dir : directories.values() ) {
	    try { dir.close(); }
	    catch ( AServException ex ) {
		logger.warn("Cannot unregister from {}", dir);
		logger.debug("IGNORED", ex);
	    }
	}
	// Close services
	for ( AlignmentServiceProfile serv : services.values() ) {
	    try { serv.close(); }
	    catch ( AServException ex ) {
		logger.debug("Cannot close {}", serv);
		logger.trace("IGNORED Exception", ex );
	    }
	}
	
	// Shut down database connection
	logger.debug("Stopping manager");
	if ( manager != null ) manager.close();
	logger.debug("Closing database connection");
	connection.close();
	logger.info("Alignment server stopped");
	System.err.close();
    }

    protected void finalize() throws Throwable {
	try { close(); }
	finally { super.finalize(); }
    }

    protected Object loadInstance( String className ) throws ClassNotFoundException, NoSuchMethodException, InstantiationException, IllegalAccessException, InvocationTargetException {
	Class<?> cl = Class.forName( className );
	java.lang.reflect.Constructor constructor = cl.getConstructor( (Class[])null );
	return constructor.newInstance( (Object[])null );
    }

    public void readParameters( String[] args ) {
	try {
	    CommandLine line = parseCommandLine( args );
	    if ( line == null ) System.exit(1); // -help

	    // Default values
	    parameters.setProperty( "host", HOST );

	    // Here deal with command specific arguments
	    
	    /* Use the given file as a database image to load */
	    //if ( line.hasOption( 'l' ) ) filename = line.getOptionValue( 'l' );
	    if ( line.hasOption( 'i' ) ) { /* external service */
		String arg = line.getOptionValue( 'i' );
		try {
		    services.put( arg, (AlignmentServiceProfile)loadInstance( arg ) );
		} catch (Exception ex) {
		    logger.warn( "Cannot create service for {}", arg );
		    logger.debug( "IGNORED Exception", ex );
		}
	    }
	    if ( line.hasOption( 'u' ) ) parameters.setProperty( "prefix", line.getOptionValue( 'u' ) );
	    if ( line.hasOption( 'H' ) ) { 
		parameters.setProperty( "http", line.getOptionValue( 'H', HTML ) );
		// This shows that it does not work
		try {
		    services.put( "fr.inrialpes.exmo.align.service.HTMLAServProfile", (AlignmentServiceProfile)loadInstance( "fr.inrialpes.exmo.align.service.HTMLAServProfile" ) );
		} catch (Exception ex) {
		    logger.warn( "Cannot create service for HTMLAServProfile", ex );
		}
	    }
	    if ( line.hasOption( 'A' ) ) { 
		parameters.setProperty( "jade", line.getOptionValue( 'A', JADE ) ); 
		try {
		    services.put( "fr.inrialpes.exmo.align.service.jade.JadeFIPAAServProfile", (AlignmentServiceProfile)loadInstance( "fr.inrialpes.exmo.align.service.jade.JadeFIPAAServProfile" ) );
		} catch ( Exception ex ) {
		    logger.warn("Cannot create service for JadeFIPAAServProfile", ex);
		}
	    }
	    if ( line.hasOption( 'W' ) ) {
		parameters.setProperty( "wsdl", line.getOptionValue( 'W', WSDL ) );
		// The WSDL extension requires HTTP server (and the same one).
		// Put the default port, may be overriden
		if ( parameters.getProperty( "http" ) == null )
		    parameters.setProperty( "http", HTML );
		try {
		    services.put( "fr.inrialpes.exmo.align.service.HTMLAServProfile", (AlignmentServiceProfile)loadInstance( "fr.inrialpes.exmo.align.service.HTMLAServProfile" ) );
		} catch ( Exception ex ) {
		    logger.warn( "Cannot create service for Web services", ex );
		}
	    }
	    if ( line.hasOption( 'X' ) ) { parameters.setProperty( "jxta", line.getOptionValue( 'P', JXTA ) ); }
	    if ( line.hasOption( 'S' ) ) { parameters.setProperty( "host", line.getOptionValue( 'S' ) ); }
	    if ( line.hasOption( 'O' ) ) { 
		try {
		    directories.put( "fr.inrialpes.exmo.align.service.OysterDirectory", (Directory)loadInstance( "fr.inrialpes.exmo.align.service.OysterDirectory" ) );
		} catch (Exception ex) {
		    logger.warn( "Cannot create directory for Oyster", ex );
		}
	    }
	    /*if ( line.hasOption( 'U' ) ) { 
		try {
		    directories.put( "fr.inrialpes.exmo.align.service.UDDIDirectory", (Directory)loadInstance( "fr.inrialpes.exmo.align.service.UDDIDirectory" ) );
		} catch (Exception ex) {
		    logger.warn("Cannot create directory for UDDI", ex);
		}
		}*/
	    if ( line.hasOption( 'm' ) ) { DBHOST = line.getOptionValue( 'm' ); }
	    if ( line.hasOption( 's' ) ) { DBPORT = line.getOptionValue( 's' ); }
	    if ( line.hasOption( 'l' ) ) { DBUSER = line.getOptionValue( 'l' ); }
	    if ( line.hasOption( 'p' ) ) { DBPASS = line.getOptionValue( 'p' ); }
	    if ( line.hasOption( 'b' ) ) { DBBASE = line.getOptionValue( 'b' ); }
	    if ( line.hasOption( 'B' ) ) { DBMS = line.getOptionValue( 'B' ); }
	    parameters.setProperty( "DBMS", DBMS );
	} catch( ParseException exp ) {
	    logger.error( exp.getMessage() );
	    usage();
	    System.exit(-1);
	}
    }

    public void usage() {
	usage( "java "+this.getClass().getName()+" [options]\nLaunch an Alignment server" );
    }
    
}
