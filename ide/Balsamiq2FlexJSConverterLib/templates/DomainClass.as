package $GrailsDomainClassPackageName$
{
	public class $GrailsDomainClassName$
	{	
		

		public function $GrailsDomainClassName$()
		{
		}
		
		public var id : uint;
		
		#for $field$ in $domainClassFields$#
		#if ($field.IsMultivalues$=='true')#
			// we may need custom add/remove functions since action script doesn't have typed array
		    public var $field.GrailsName$:Array; //$field.GORMTypeCore$
			public function get $field.GrailsName$AsString() : String 
			{
				if ($field.GrailsName$ == null)
				{
					return null;
				} else {
					return $field.GrailsName$.join(";");	
				}
			}
			public function set $field.GrailsName$AsString( asWholeString: String) : void 
			{
				if (asWholeString == null || asWholeString.length == 0)
				{
					//nothing to do
					
				} else {
					var wholeStringLength:int = asWholeString.length;
					
					if ( asWholeString.lastIndexOf(";") == wholeStringLength - 1)
						asWholeString = asWholeString.substr(0, wholeStringLength - 1)
					var values:Array = asWholeString.split(";");
					$field.GrailsName$ = new Array();
					for each (var n:String in values) 
					{
						#if ($field.GORMTypeCore$=='String')# $field.GrailsName$.push(new String(n)); #endif#
						#if ($field.GORMTypeCore$=='Integer')# $field.GrailsName$.push(int(n)); #endif#
						#if ($field.GORMTypeCore$=='Long')# $field.GrailsName$.push(new Number(n)); #endif#
						#if ($field.GORMTypeCore$=='Float')# $field.GrailsName$.push(new Number(n)); #endif#
						#if ($field.GORMTypeCore$=='Double')# $field.GrailsName$.push(new Number(n)); #endif#
						#if ($field.GORMTypeCore$=='BigDecimal')#$field.GrailsName$.push(new Number(n)); #endif#
						#if ($field.GORMTypeCore$=='Date')# $field.GrailsName$.push(new Date(n)); #endif#
						#if ($field.GORMTypeCore$=='Time')# $field.GrailsName$.push(new Date(n)); #endif#
						#if ($field.GORMTypeCore$=='Byte')# $field.GrailsName$.push(new String(n)); #endif#
					}
				}
			}
		#else#
		    public var $field.GrailsName$:
			#if ($field.GORMTypeCore$=='String')# String; #endif#
			#if ($field.GORMTypeCore$=='Integer')# int; #endif#
			#if ($field.GORMTypeCore$=='Long')# Number; #endif#
			#if ($field.GORMTypeCore$=='Float')# Number; #endif#
			#if ($field.GORMTypeCore$=='Double')# Number; #endif#
		    #if ($field.GORMTypeCore$=='BigDecimal')#Number; #endif#
			#if ($field.GORMTypeCore$=='Date')# Date; #endif#
			#if ($field.GORMTypeCore$=='Time')# Date; #endif#
			#if ($field.GORMTypeCore$=='Byte')# String; #endif#
		#endif#
		       public var $field.GrailsName$GROMRawType:String = '$field.GORMTypeCore$';
		
		#endfor#
	}
}

