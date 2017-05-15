package moonshine;

import java.io.IOException;
import java.net.URI;
import java.nio.BufferUnderflowException;
import java.nio.channels.ClosedChannelException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.concurrent.CompletableFuture;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.nextgenactionscript.vscode.ActionScriptTextDocumentService;
import org.eclipse.lsp4j.CompletionList;
import org.eclipse.lsp4j.DidChangeTextDocumentParams;
import org.eclipse.lsp4j.DidOpenTextDocumentParams;
import org.eclipse.lsp4j.DocumentSymbolParams;
import org.eclipse.lsp4j.Hover;
import org.eclipse.lsp4j.Location;
import org.eclipse.lsp4j.ReferenceParams;
import org.eclipse.lsp4j.SignatureHelp;
import org.eclipse.lsp4j.SymbolInformation;
import org.eclipse.lsp4j.TextDocumentContentChangeEvent;
import org.eclipse.lsp4j.TextDocumentIdentifier;
import org.eclipse.lsp4j.TextDocumentItem;
import org.eclipse.lsp4j.TextDocumentPositionParams;
import org.eclipse.lsp4j.VersionedTextDocumentIdentifier;
import org.eclipse.lsp4j.WorkspaceSymbolParams;
import org.xsocket.MaxReadSizeExceededException;
import org.xsocket.connection.IDataHandler;
import org.xsocket.connection.INonBlockingConnection;

public class xSocketDataHandler implements IDataHandler
{
    private static final String osName = System.getProperty("os.name").toLowerCase();
    private static final boolean isMacOs = osName.startsWith("mac os x");

    private ActionScriptTextDocumentService txtSrv = new ActionScriptTextDocumentService();
    private String fileUrl = "";
    private String flexLibPath = "";
    private MoonshineProjectConfigStrategy projectConfigStrategy = new MoonshineProjectConfigStrategy();
    private MoonshineLanguageClient languageClient = new MoonshineLanguageClient();

    {
        txtSrv.setProjectConfigStrategy(projectConfigStrategy);
        txtSrv.setLanguageClient(languageClient);
    }
    // ByteBuffer buffer = ByteBuffer.allocate(1024);
    

    public String readTextFile(String filePath)
    {
        String content = "";
        try
        {
            content = new String(Files.readAllBytes(Paths.get(filePath)));
        }
        catch (IOException e)
        {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        return content;
    }
    
    public boolean onData(INonBlockingConnection nbc) throws IOException, BufferUnderflowException, ClosedChannelException, MaxReadSizeExceededException
    {
        languageClient.connection = nbc;
        try
        {
            int index = nbc.indexOf("\0");
            if(index == -1)
            {
                //the full data has not yet arrived -JT
                return false;
            }
            nbc.setAutoflush(true);
            String data = nbc.readStringByDelimiter("\0");

            //JOptionPane.showMessageDialog(null, "data from flex : " + data);
            if (data.equalsIgnoreCase("SHUTDOWN"))
            {
                Main.shutdownServer();
            }
            else
            {

                Gson g = new Gson();
                JsonObject jsonObject = new JsonParser().parse(data).getAsJsonObject();

                int requestID = jsonObject.get("id").getAsInt();
                JsonObject param = jsonObject.getAsJsonObject("params");
                String method = jsonObject.get("method").getAsString();

                if (method.equalsIgnoreCase("textDocument/flexjspath"))
                {
                    if (!param.get("flexJSPath").getAsString().equals(""))
                    {

                        flexLibPath = param.get("flexJSPath").getAsString().concat("/frameworks");
                        System.clearProperty("flexlib");
                        System.setProperty("flexlib", flexLibPath);
                    }
                }
                else if (method.equalsIgnoreCase("textDocument/didOpen"))
                {
                    try
                    {

                        TextDocumentItem txtDocItm = g.fromJson(param.get("textDocument"), TextDocumentItem.class);
                        fileUrl = txtDocItm.getUri();
                        txtDocItm.setUri(fileUrl);
                        
                        String uriToNativePath = Paths.get(new URI(fileUrl)).toFile().getAbsolutePath();
                        txtDocItm.setText(readTextFile(uriToNativePath));

                        DidOpenTextDocumentParams didOpenTxtParam = new DidOpenTextDocumentParams()
                        {


                            @Override
                            public TextDocumentItem getTextDocument()
                            {
                                // TODO Auto-generated method stub
                                return txtDocItm;
                            }

                            @Override
                            public String getUri()
                            {
                                // TODO Auto-generated method stub
                                return fileUrl;
                            }

                            @Override
                            public String getText()
                            {
                                // TODO Auto-generated method stub
                                return txtDocItm.getText();
                            }

                        };
                        //JOptionPane.showMessageDialog(null, didOpenTxtParam);
                        txtSrv.didOpen(didOpenTxtParam);
                    }
                    catch (Exception e)
                    {
                        e.printStackTrace();
                        System.err.println("Error didopen: " + e.getMessage());
                    }
                }
                else if (method.equalsIgnoreCase("workspace/didChangeConfiguration"))
                {
                    JsonObject version = param.getAsJsonObject("DidChangeConfigurationParams");
                    projectConfigStrategy.setChanged(true);
                    projectConfigStrategy.setConfigParams(version);
                }
                else if (method.equalsIgnoreCase("textDocument/didChange"))
                {
                    try
                    {
                        JsonObject version = param.getAsJsonObject("DidChangeTextDocumentParams");

                        VersionedTextDocumentIdentifier versionTxtDoc = g.fromJson(version.get("textDocument"), VersionedTextDocumentIdentifier.class);
                        List<TextDocumentContentChangeEvent> val = new ArrayList<TextDocumentContentChangeEvent>();
                        val.add(g.fromJson(version.get("contentChanges"), TextDocumentContentChangeEvent.class));

                        DidChangeTextDocumentParams changeTxtParam = new DidChangeTextDocumentParams()
                        {

                            @Override
                            public String getUri()
                            {
                                // TODO Auto-generated method stub
                                return versionTxtDoc.getUri();
                            }

                            @Override
                            public VersionedTextDocumentIdentifier getTextDocument()
                            {
                                // TODO Auto-generated method stub
                                return versionTxtDoc;
                            }

                            @Override
                            public List<TextDocumentContentChangeEvent> getContentChanges()
                            {
                                // TODO Auto-generated method stub

                                return val;
                            }
                        };
                        txtSrv.didChange(changeTxtParam);
                    }
                    catch (Exception e)
                    {
                        System.err.println("Error didchange: " + e.getMessage());
                    }
                }
                else if (method.equalsIgnoreCase("textDocument/completion"))
                {
                    try
                    {
                        TextDocumentPositionParams txtPosParam = g.fromJson(param.getAsJsonObject("TextDocumentPositionParams"), TextDocumentPositionParams.class);
                        CompletableFuture<CompletionList> lst = txtSrv.completion(txtPosParam);
                        //Collections.sort(lst);

                        String json = getJSON(requestID, lst.get());
                        System.out.println("completion result : " + json);
                        nbc.write(json + "\0");

                    }
                    catch (Exception e)
                    {
                        System.err.println("Error completion: " + e.getMessage());
                    }
                }
                else if (method.equalsIgnoreCase("textDocument/hover"))
                {
                    TextDocumentPositionParams txtPosParam = g.fromJson(param.getAsJsonObject("TextDocumentPositionParams"), TextDocumentPositionParams.class);

                    CompletableFuture<Hover> hoverInfo = txtSrv.hover(txtPosParam);
                    String json = getJSON(requestID, hoverInfo.get());
                    System.out.println("hover result : " + json);
                    nbc.write(json + "\0");
                }
                else if (method.equalsIgnoreCase("textDocument/signatureHelp"))
                {
                    TextDocumentPositionParams txtPosParam = g.fromJson(param.getAsJsonObject("TextDocumentPositionParams"), TextDocumentPositionParams.class);
                    CompletableFuture<SignatureHelp> signatureInfo = txtSrv.signatureHelp(txtPosParam);
                    String json = getJSON(requestID, signatureInfo.get());
                    System.out.println("signature help result : " + json);
                    nbc.write(json + "\0");
                }
                else if (method.equalsIgnoreCase("textDocument/definition"))
                {
                    TextDocumentPositionParams txtPosParam = g.fromJson(param.getAsJsonObject("TextDocumentPositionParams"), TextDocumentPositionParams.class);
                    CompletableFuture<List<? extends Location>> signatureInfo = txtSrv.definition(txtPosParam);
                    String json = getJSON(requestID, signatureInfo.get());
                    System.out.println("definition result: " + json);
                    nbc.write(json + "\0");
                }
                else if (method.equalsIgnoreCase("textDocument/documentSymbol"))
                {
                    DocumentSymbolParams docSymbolParams = g.fromJson(param.getAsJsonObject("DocumentSymbolParams"), DocumentSymbolParams.class);
                    CompletableFuture<List<? extends SymbolInformation>> symbolInfo = txtSrv.documentSymbol(docSymbolParams);
                    String json = getJSON(requestID, symbolInfo.get());
                    System.out.println("document symbol result: " + json);
                    nbc.write(json + "\0");
                }
                else if (method.equalsIgnoreCase("workspace/symbol"))
                {
                    WorkspaceSymbolParams workspaceSymbolParams = g.fromJson(param.getAsJsonObject("WorkspaceSymbolParams"), WorkspaceSymbolParams.class);
                    CompletableFuture<List<? extends SymbolInformation>> symbolInfo = txtSrv.workspaceSymbol(workspaceSymbolParams);
                    String json = getJSON(requestID, symbolInfo.get());
                    System.out.println("workspace symbol result: " + json);
                    nbc.write(json + "\0");
                }
                else if (method.equalsIgnoreCase("textDocument/references"))
                {
                    ReferenceParams refParams = g.fromJson(param.getAsJsonObject("ReferenceParams"), ReferenceParams.class);
                    CompletableFuture<List<? extends Location>> refs = txtSrv.references(refParams);
                    String json = getJSON(requestID, refs.get());
                    System.out.println("references result: " + json);
                    nbc.write(json + "\0");
                }
            }
        }
        catch (Exception ex)
        {
            ex.printStackTrace();
            System.out.println(ex.getMessage() + "data handler " + ex.getStackTrace());
        }

        return true;
    }

    private String getJSON(int id, Object result)
    {
        HashMap<String, Object> wrapper = new HashMap<>();
        wrapper.put("id", id);
        wrapper.put("result", result);
        return new Gson().toJson(wrapper);
    }

}
