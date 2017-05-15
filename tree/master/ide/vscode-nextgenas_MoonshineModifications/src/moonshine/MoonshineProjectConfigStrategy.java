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
package moonshine;

import com.google.gson.JsonObject;
import com.nextgenactionscript.vscode.project.CompilerOptions;
import com.nextgenactionscript.vscode.project.IProjectConfigStrategy;
import com.nextgenactionscript.vscode.project.ProjectOptions;
import com.nextgenactionscript.vscode.project.ProjectType;

/**
 * Configures a project for Moonshine IDE.
 */
public class MoonshineProjectConfigStrategy implements IProjectConfigStrategy
{
    private ProjectOptions options;
    private boolean changed = true;

    public MoonshineProjectConfigStrategy()
    {
    }

    public boolean getChanged()
    {
        return changed;
    }

    public void setChanged(boolean value)
    {
        changed = value;
    }

    public void setConfigParams(JsonObject params)
    {
        if (options == null)
        {
            options = new ProjectOptions();
        }
        options.type = ProjectType.APP;
        options.config = params.get("config").getAsString();
        String compFiles = params.get("uri").getAsString();
        options.files = compFiles.split(",");
        options.compilerOptions = new CompilerOptions();
    }

    public ProjectOptions getOptions()
    {
        changed = false;
        if (options == null)
        {
            return null;
        }
        return options;
    }
}
