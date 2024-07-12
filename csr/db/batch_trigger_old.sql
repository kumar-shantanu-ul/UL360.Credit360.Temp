set define off
CREATE OR REPLACE AND COMPILE JAVA SOURCE NAMED csr."BatchTrigger" AS

import java.net.DatagramSocket;
import java.net.DatagramPacket;
import java.net.InetAddress;

public class BatchTrigger {

    public static void send (String broadcastAddresses, int defaultPort, long value)
        throws java.net.SocketException, java.io.IOException
	{
		String host = "255.255.255.255";
		byte[] data = new byte[] {
			(byte)(value >> 56),
			(byte)(value >> 48),
			(byte)(value >> 40),
			(byte)(value >> 32),
			(byte)(value >> 24),
			(byte)(value >> 16),
			(byte)(value >> 8),
			(byte)(value)
		};
        DatagramSocket s = new DatagramSocket();
        DatagramPacket p = new DatagramPacket(data, data.length, InetAddress.getByName(host), defaultPort);

        p.setData(data);
        s.send(p);
		s.close();
    }

};

/
