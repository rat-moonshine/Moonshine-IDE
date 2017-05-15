package moonshine;

import java.io.IOException;
import java.net.SocketException;
import java.net.UnknownHostException;

import org.xsocket.connection.IServer;
import org.xsocket.connection.Server;

public class Main
{
    protected static IServer srv = null;

    public static void main(String[] args)
    {
        try
        {
            srv = new Server(58080, new xSocketDataHandler());
            srv.run();
        }
        catch (SocketException e)
        {
            e.printStackTrace();
        }
        catch (UnknownHostException e)
        {
            System.err.println("Error: " + e.toString());
            e.printStackTrace();

        }
        catch (IOException e)
        {
            // TODO Auto-generated catch block
            System.err.println("Error: " + e.toString());
            e.printStackTrace();
        }
        catch (Throwable e)
        {
            e.printStackTrace();
        }
    }

    protected static void shutdownServer()
    {
        try
        {
            srv.close();

        }
        catch (Exception ex)
        {
            System.err.println("Error: " + ex.toString());
            ex.printStackTrace();
        }

    }
}


