package com.nextgenactionscript.vscode;


import java.io.IOException;

import java.nio.BufferUnderflowException;
import java.nio.ByteBuffer;
import java.nio.channels.ClosedChannelException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;


import org.xsocket.*;
import org.xsocket.connection.*;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import io.typefox.lsapi.ClientCapabilities;
import io.typefox.lsapi.CompletionList;
import io.typefox.lsapi.DidChangeTextDocumentParams;
import io.typefox.lsapi.DidOpenTextDocumentParams;
import io.typefox.lsapi.Hover;
import io.typefox.lsapi.InitializeParams;
import io.typefox.lsapi.TextDocumentContentChangeEvent;
import io.typefox.lsapi.TextDocumentItem;
import io.typefox.lsapi.VersionedTextDocumentIdentifier;
import io.typefox.lsapi.impl.TextDocumentContentChangeEventImpl;
import io.typefox.lsapi.impl.TextDocumentItemImpl;
import io.typefox.lsapi.impl.TextDocumentPositionParamsImpl;
import io.typefox.lsapi.impl.VersionedTextDocumentIdentifierImpl;


 
 
public class xSocketDataHandler implements IDataHandler
{
      private static final String osName = System.getProperty("os.name").toLowerCase();
      private static final boolean isMacOs = osName.startsWith("mac os x");

	  ActionScriptTextDocumentService txtSrv = new ActionScriptTextDocumentService();
	  String fileUrl = "";
	  String flexLibPath="";
	  ActionScriptLanguageServer server = new ActionScriptLanguageServer();
	 // ByteBuffer buffer = ByteBuffer.allocate(1024);
	  
	  public String readTextFile(String filePath){
		 String content="";
		 try {
			 content = new String(Files.readAllBytes(Paths.get(filePath)));
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}	
		 return content;
	    }
	 
	
    public boolean onData(INonBlockingConnection nbc) throws IOException, BufferUnderflowException, ClosedChannelException, MaxReadSizeExceededException
    {
        try
        { 
        	nbc.setAutoflush(true);
        	String data = nbc.readStringByDelimiter("\0");
        	
        	//JOptionPane.showMessageDialog(null, "data from flex : " + data);
        	if(data.equalsIgnoreCase("SHUTDOWN")){
        		  Main.shutdownServer();
        	 }
        	 else{
        	 
	            Gson g = new Gson();
	            JsonObject jsonObject = new JsonParser().parse(data).getAsJsonObject();
	                 
	            JsonObject param = jsonObject.getAsJsonObject("params");
	            String method = jsonObject.get("method").getAsString();
	           
	            
	            if(method.equalsIgnoreCase("textDocument/flexjspath")){
	            	
		       		 ClientCapabilities capabilities = new ClientCapabilities() {
		    			};
		    			
		       		 InitializeParams params = new InitializeParams() {
		    				
		    				@Override
		    				public String getRootPath() {
		    					// TODO Auto-generated method stub
		    					return "";
		    				}
		    				
		    				@Override
		    				public Integer getProcessId() {
		    					// TODO Auto-generated method stub
		    					return 152;
		    				}
		    				
		    				@Override
		    				public String getClientName() {
		    					// TODO Auto-generated method stub
		    					return "";
		    				}
		    				
		    				@Override
		    				public ClientCapabilities getCapabilities() {
		    					// TODO Auto-generated method stub
		    					return capabilities;
		    				}
		    			};
		    			server.initialize(params);
	            	if(!param.get("flexJSPath").getAsString().equals("")){
	            		
	            		flexLibPath = param.get("flexJSPath").getAsString().concat("/frameworks");
	            		System.clearProperty("flexlib");
	            		System.setProperty("flexlib", flexLibPath);
	            	
	            		server.initialize(params);
	            	}else{
	          	 		server.exit();
	            		System.setProperty("flexlib", "");
	            	}
	             }
		          else if(method.equalsIgnoreCase("textDocument/didOpen"))
		            {
		          try{
		        	 
		            	TextDocumentItemImpl txtDocItm = g.fromJson(param.get("textDocument"), TextDocumentItemImpl.class);
		            	txtDocItm.setText(readTextFile(txtDocItm.getUri()));
		            	if(!isMacOs)
		            		fileUrl = "file:///"+txtDocItm.getUri().replace("\\", "/");
		            	else{
		            		if(!txtDocItm.getUri().toString().startsWith("file://"))
			            		fileUrl = "file://"+txtDocItm.getUri();
			            	else
			            		fileUrl = txtDocItm.getUri();
		            	}
		            	
		            	txtDocItm.setUri(fileUrl);
		            	
		            	DidOpenTextDocumentParams didOpenTxtParam = new DidOpenTextDocumentParams() {
						
						
						@Override
						public TextDocumentItem getTextDocument() {
							// TODO Auto-generated method stub
							return txtDocItm;
						}
		
						@Override
						public String getUri() {
							// TODO Auto-generated method stub
							return fileUrl;
						}
		
						@Override
						public String getText() {
							// TODO Auto-generated method stub
							return txtDocItm.getText();
						}
						
					};
		   		//JOptionPane.showMessageDialog(null, didOpenTxtParam);
		             txtSrv.didOpen(didOpenTxtParam);
		            }catch(Exception e){
		            	System.err.println("Error didopen: " + e.getMessage());
			          }
	            }
	            else if(method.equalsIgnoreCase("workspace/didChangeConfiguration")){
	            
	            	JsonObject version = param.getAsJsonObject("DidChangeConfigurationParams");
	            	txtSrv.asconfigChanged = true;
	            	txtSrv.currentOptions = null;
	            	txtSrv.setConfig(version.get("config").getAsString());
	            	String compFiles = version.get("uri").getAsString();
	            	String[] compilefiles = compFiles.split(",");
	            	txtSrv.setCompilefiles(compilefiles);
	            	
	            	
	            }
	            else if(method.equalsIgnoreCase("textDocument/didChange")){
	          try{
	            	JsonObject version = param.getAsJsonObject("DidChangeTextDocumentParams");
	            	
	            	VersionedTextDocumentIdentifierImpl versionTxtDoc = g.fromJson(version.get("textDocument"), VersionedTextDocumentIdentifierImpl.class);
	            	List<TextDocumentContentChangeEventImpl> val = new ArrayList<TextDocumentContentChangeEventImpl>();
	            	val.add(g.fromJson(version.get("contentChanges"), TextDocumentContentChangeEventImpl.class));
	            	
						DidChangeTextDocumentParams changeTxtParam = new DidChangeTextDocumentParams() {
							
							@Override
							public String getUri() {
								// TODO Auto-generated method stub
								return versionTxtDoc.getUri();
							}
							
							@Override
							public VersionedTextDocumentIdentifier getTextDocument() {
								// TODO Auto-generated method stub
								return versionTxtDoc;
							}
							
							@Override
							public List<? extends TextDocumentContentChangeEvent> getContentChanges() {
								// TODO Auto-generated method stub
								
								return  val;
							}
						};
						txtSrv.didChange(changeTxtParam);	
	          }catch(Exception e){
	        	  System.err.println("Error didchange: " + e.getMessage());
	          }
	            }
	            else if(method.equalsIgnoreCase("textDocument/completion")){
	            	try{
	            	TextDocumentPositionParamsImpl txtPosParam = g.fromJson(param.getAsJsonObject("TextDocumentPositionParams"), TextDocumentPositionParamsImpl.class);
	            	CompletableFuture<CompletionList> lst =  txtSrv.completion(txtPosParam);
	            	//Collections.sort(lst);
	            	 
	  				String json = new Gson().toJson(lst);
	  				System.out.println("completion result : " + json);
	  				 nbc.write(json+"\0");
	  				
	            }catch(Exception e){
	            	System.err.println("Error completion: " + e.getMessage());
		          }
	            	}
	            else if(method.equalsIgnoreCase("textDocument/hover")){
	            	TextDocumentPositionParamsImpl txtPosParam = g.fromJson(param.getAsJsonObject("TextDocumentPositionParams"), TextDocumentPositionParamsImpl.class);
	            	
	            	CompletableFuture<Hover> hoverInfo = txtSrv.hover(txtPosParam);
	            	String json = new Gson().toJson(hoverInfo);
	  				 nbc.write(json+"\0");
	            }
				else if(method.equalsIgnoreCase("textDocument/signatureHelp")){
					            	
				}
				else if(method.equalsIgnoreCase("textDocument/definition")){
					
				}
				else if(method.equalsIgnoreCase("textDocument/references")){
					
				}
	        	 }
        }
        catch(Exception ex)
        {
        	ex.printStackTrace();
        	nbc.write(ex.getStackTrace()+"\0");
            System.out.println(ex.getMessage() + "data handler "+ex.getStackTrace());
        }
 
        return true;
    }
   
}
