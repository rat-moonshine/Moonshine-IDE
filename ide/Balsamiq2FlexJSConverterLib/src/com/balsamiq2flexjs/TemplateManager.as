////////////////////////////////////////////////////////////////////////////////
// Copyright 2016 Prominic.NET, Inc.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
// http://www.apache.org/licenses/LICENSE-2.0 
// 
// Unless required by applicable law or agreed to in writing, software 
// distributed under the License is distributed on an "AS IS" BASIS, 
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and 
// limitations under the License
//
// Author: Prominic.NET, Inc. 
// No warranty of merchantability or fitness of any kind. 
// Use this software at your own risk.
////////////////////////////////////////////////////////////////////////////////
package com.balsamiq2flexjs
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.getQualifiedClassName;
	
	public class TemplateManager
	{
		public function TemplateManager()
		{
			
			
			
		}
		
		//const booleanExpressionPattern:String = "(?P<left>[\w\$\[\]\"\']*) *(?P<operator>[=<>\!]*) *(?P<right>[\w\$\[\]\"\']*)";
		
		
		private function calculateBooleanExpression(left: String, operator:String, right: String, parameters:Object): Boolean
		{
			// TODO support logic operator?
			var leftValue:Object =  getValueOfParameterOrConstants(left, parameters);
			var rightValue:Object =  getValueOfParameterOrConstants(right, parameters);
			
			switch (operator) 
			{
				case "==":
					return leftValue == rightValue;
					break;
				case "!=":
					return leftValue != rightValue;
					break;
				case ">":
					return leftValue > rightValue;
					break;
				case "<":
					
					return leftValue < rightValue;
					break;
				case ">=":
				case "=<":
					return leftValue >= rightValue;
					break;
				case "<=":
				case "=<":
					return leftValue <= rightValue;
					break;
				default:
					return false;
				
			}
		}
		private function getValueOfParameterOrConstants(expression: String, parameters:Object ): Object
		{
			
			var value : Object;
			if (expression.length == 0) {
				value = null;
			} else {
				if (expression.charAt(0) == '$'  && expression.charAt(expression.length-1) == '$' ) {
					// parameter 
					var parameterName:String = expression.substr(1, expression.length-2);
					
					if (parameterName.indexOf("[") > -1 && parameterName.indexOf("]") > -1)
					{
						
						parameterName = parameterName.split("[").join(".");
						parameterName = parameterName.split("]").join("");
						
					}
					//trace("parameterName = " + parameterName);
					
					
					var parameterLeveledNameList:Array = parameterName.split(".");
					var currentHolder:Object = parameters;
					for (var i:int = 0; i < parameterLeveledNameList.length; i++) {
						var currentNameInCurrentHolder:String = parameterLeveledNameList[i];
						var currentValue:Object = currentHolder[currentNameInCurrentHolder];
						//trace(currentNameInCurrentHolder +" = " + currentValue);
						if (currentValue == null) {
							value = currentValue;
							break;
						} else {
							
							value = currentValue;
							currentHolder = currentValue;
						}
					}
				} else {
					// constants, we support number and string only
					if ((expression.charAt(0) == '"' && expression.charAt(expression.length - 1) == '"')
						|| (expression.charAt(0) == "'" && expression.charAt(expression.length - 1) == "'")) {
						// String
						if (expression.length > 1) {
							value = expression.substr(1, expression.length - 2);	
						} else {
							// bad constant
							value = null;
							
						}
						
					} else {
						// support number only 
						value = new Number(expression);
					}
				}
			}
			//trace("value of " + expression + "=" + value);
			return value;
			
		}
		
		public function process(template:String, parameters:Object) : String
		{
			
			// process for
			/*
			
			#for ( $n in $properties)#
			
			#endfor#
			
			*/
			var pattern:RegExp = /#for *(?P<variable>[\w\.\$]*) *in *(?P<collection>[\w\.\$]*)#(?P<looped>.*?)#endfor#/sg; 
			var result:Array = pattern.exec(template); 
			
			var forProcessed:String = template;
			
			while (result != null) 
			{ 
				//trace("for variable=" + result.variable + " collection=" + result.collection + " looped="  + result.looped);
				
				// process on loop
				if (result.collection == null || result.variable == null) {
					// TODO throw error bad syntax
					break;
				}
				if (parameters == null) {
					
					trace (result.collection + " not set!");
					break;
				}
				//var collection = parameters[result.collection];
				var collection:Object = getValueOfParameterOrConstants(result.collection, parameters);
				
				if (collection == null) {
					
					trace (result.collection + " not set!");
					break;
				}
				
				
				if (getQualifiedClassName(collection) != "Array") {
					
					trace (result.collection + " is NOT Array");
					break;
				}
				var looped:String = "";
				
				
				for (var j:int = 0; j < collection.length; j++) {
					var oneLooped:String = result.looped;
					var loopVariable:String = result.collection.substr(0, result.collection.length - 1) + "[" + j+ "]";
					
					oneLooped = oneLooped.split(result.variable.substr(0, result.variable.length - 1)).join(loopVariable);
					//trace("one loop on" + loopVariable);
					//trace("looped would be" + oneLooped);
					looped += oneLooped;
				}
				
				forProcessed = forProcessed.replace(result[0], looped);
				result = pattern.exec(template);
				
			}			
			
			//return forProcessed;
			// process if
			template = forProcessed;
			
			while (template.indexOf("#if") > -1) {
			
			pattern = /#if *\(?(?P<left>[\w\$\.\[\]\"\']*) *(?P<operator>[=<>\!]*) *(?P<right>[:-_\w\$\.\[\]\"\']*)\)? *#(?P<trueBlock>[^#]*?)(?P<falseBlock>#else#[^#]*?)?#endif#/sg; 
			result = pattern.exec(template); 
			
			var ifProcessed:String = template;
			
			while (result != null) 
			{ 
				//trace("left=" + result.left + " right=" + result.right +" trueBlock=" + result.trueBlock);
				
				var booleanValue:Boolean = calculateBooleanExpression(result.left, result.operator, result.right, parameters);
			
				var tested:String;
				if (booleanValue) {
					tested = result.trueBlock;
				} else {
					if (result.falseBlock != null) 
					{
						result.falseBlock = result.falseBlock.replace("#else#", "");
					tested = result.falseBlock;
					} else {
						tested = "";
					}
				}
				ifProcessed = ifProcessed.replace(result[0], tested);
				result = pattern.exec(template);
				
			}			
			
			    template = ifProcessed;
			}
			
			// replace variables
			
			pattern = /\$[\w\[\]\.]+\$/sg; 
			
			var variableProcessed:String = template;
			result = pattern.exec(template); 
			while (result != null) 
			{ 
				//trace("variable=" + result[0]);
				
				var value1:Object = getValueOfParameterOrConstants(result[0], parameters);
				
				variableProcessed = variableProcessed.replace(result[0], value1);
				result = pattern.exec(template);
				
			}			
			
			
//			pattern = /#[\w\[\]\.]+#/sg; 
//			
//			variableProcessed = variableProcessed;
//			result = pattern.exec(template); 
//			while (result != null) 
//			{ 
//				trace("variable=" + result[0]);
//				
//				var value2:Object = getValueOfParameterOrConstants(result[0], parameters);
//				
//				variableProcessed = variableProcessed.replace(result[0], value2);
//				result = pattern.exec(template);
//				
//			}			
			
			
			
			
			var duplicatedLineEndsRemoved:String =  variableProcessed.replace(/\n[\s]+\n/g,"\n");
			return duplicatedLineEndsRemoved;
			
//			return ifProcessed;
//			return forProcessed;
		}
		
		
		public function CopyTemplateFileTO_templateReaded(templateContent:String, targetFileName:String, parameters: Object) : void
		{
			
			var file:File = File.desktopDirectory.resolvePath(targetFileName);
			var stream:FileStream = new FileStream();
			var strMXMLAll:String;
			var xml:XML;
			var strWrite:String = templateContent;
			
			// process variables
			//var domainName:String = getDomainName();
			//strWrite = strWrite.replace(/#DomainName#/gi, domainName);
//			
//			var parameters: Object = new Object();
//			
//			//parameters["$properties"] = new Array("bad1", "BAD2");
//			
//			parameters["GrailsDomainClassName"] = "BOOOO";
//			parameters["domainClassFields"] = new Array();
////			
//			var field1:Object = new Object();
//			field1['FieldName']='height';
//			field1['type']='int';
////			
//			var field2:Object = new Object();
//			field2['FieldName']='Address';
//			field2['type']='String';
//			parameters["domainClassFields"].push(field1);
//			parameters["domainClassFields"].push(field2);
			
			
//			trace ("array " + parameters.properties[1]);
			strWrite = process(templateContent, parameters);
			
			trace("copy tempalte TO " + targetFileName);
			stream.open(file, FileMode.WRITE);
			stream.writeUTFBytes(strWrite);
			stream.close();
			
		}
	}
}
