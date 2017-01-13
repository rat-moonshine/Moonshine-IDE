/*
Copyright 2016 Bowler Hat LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
package com.nextgenactionscript.vscode;

import java.io.IOException;

import java.net.SocketException;
import java.net.UnknownHostException;
import org.xsocket.connection.IServer;
import org.xsocket.connection.Server;


/**
 * Contains the entry point for the JAR.
 */
public class Main
{
    private static final int MISSING_PORT = 100;
    private static final int SERVER_CONNECT_ERROR = 101;

    /**
     * The main entry point when the JAR is run. Opens a socket to communicate
     * with Visual Studio Code using the port specified with the
     * -Dnextgeas.vscode.port command line option. Then, instantiates the
     * ActionScriptLanguageServer, and passes it to an instance of the
     * LanguageServerToJsonAdapter class provided by the typefox/ls-api library,
     * which handles all of the language server protocol communication.
     * 
     * LanguageServerToJsonAdapter calls methods on ActionScriptLanguageServer
     * as requests come in from VSCode.
     */
    protected static IServer srv = null;
    public static void main(String[] args)
    {
    	try{
    		srv = new Server(58080, new xSocketDataHandler());
    		srv.run();
        	} catch (SocketException e)
            {
                e.printStackTrace();
            }
      /*  String port = System.getProperty("nextgeas.vscode.port");
        if (port == null)
        {
            System.err.println("Error: System property nextgeas.vscode.port is required.");
            System.exit(MISSING_PORT);
        }
        try
        {
            Socket socket = new Socket("localhost", Integer.parseInt(port));

            ActionScriptLanguageServer server = new ActionScriptLanguageServer();

            LanguageServerToJsonAdapter jsonServer = new LanguageServerToJsonAdapter(server);
            jsonServer.connect(socket.getInputStream(), socket.getOutputStream());
            jsonServer.getProtocol().addErrorListener((message, error) -> {
                System.err.println(message);
                if (error != null)
                {
                    error.printStackTrace();
                }
            });

            jsonServer.join();
        }
        catch (Throwable t)
        {
            System.err.println("Error: " + t.toString());
            System.exit(SERVER_CONNECT_ERROR);
        }
    }
}*/
catch (UnknownHostException e) {
	System.err.println("Error: " + e.toString());
	e.printStackTrace();
	
} catch (IOException e) {
	// TODO Auto-generated catch block
	System.err.println("Error: " + e.toString());
	e.printStackTrace();
}
catch (Throwable e) {
    e.printStackTrace();
}
}
protected static void shutdownServer()
{
try
{
    srv.close();
 
  }
catch(Exception ex)
{
	System.err.println("Error: " + ex.toString());
	ex.printStackTrace();
}

}
}


