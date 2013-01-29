
  require ( "enso" )
  
     MObject = MakeClass({ _class_ : { seq_no : 0 },
       _id : function ( ) { return this.$. _id } ,
       initialize : function (data, root) { var self=this;
         self.$._id = self._class_.seq_no = self._class_.seq_no + 1 ;
         self.$.data = data ;
         self.$.root = root || self ; } ,
       schema_class : function () { var self=this; {
         var res = self.$.root.types().GET(self.$.data.GET("class")) ;
         self.define_singleton_method("schema_class" , function () { return res ; }) ;
         return res ; } } ,
       GET : function (sym) { var self=this; {
         var res = sym.GET((- 1)) == "?" ? self.schema_class().name() == sym.slice(
          0,
           ( sym.length() - 1)) : self.$.data.has_key( str( sym, "=")) ? self.$.data.GET(
           str( sym, "=")) : self.$.data.has_key( str( sym, "#")) ? Boot.make_field(
          self.$.data.GET( str( sym, "#")),
           self.$.root,
           true) : self.$.data.has_key( sym.to_s()) ? Boot.make_field(
          self.$.data.GET( sym.to_s()),
           self.$.root,
           false) : raise(
           str(
            "Trying to deref nonexistent field ",
             sym,
             " in ",
             self.$.data.to_s().slice(0, 300))) ;
         self.define_singleton_method( sym , function () { return res ; }) ;
         return res ; } } ,
       eql : function (other) { var self=this; { return self._id() == other._id() ; } } ,
       to_s : function () { var self=this; { return self.$.name || (self.$.name =((function(){ { try { return str(
        "<",
         self.$.data.GET("class"),
         " ",
         self.name(),
         ">") ; }
         catch ( DUMMY ) { return str(
          "<",
           self.$.data.GET("class"),
           " ",
           self._id(),
           ">") ; } } })())) ; } } })
     Schema = MakeClass( MObject, { _class_ : { },
       classes : function () { var self=this; { return BootManyField(
         self.types().select(function (t) { return t.Class() ; }),
         self.$.root,
         true) ; } } ,
       primitives : function () { var self=this; { return BootManyField(
         self.types().select(function (t) { return t.Primitive() ; }),
         self.$.root,
         true) ; } } })
     Class = MakeClass( MObject, { _class_ : { },
       all_fields : function () { var self=this; { return BootManyField(
        ( self.supers().flat_map(function (s) { return s.all_fields() ; }) + defined_fields),
         self.$.root,
         true) ; } } ,
       fields : function () { var self=this; { return BootManyField(
         self.all_fields().select(function (f) { return ! f.computed() ; }),
         self.$.root,
         true) ; } } })
     BootManyField = MakeClass( Array, { _class_ : { },
       initialize : function (arr, root, keyed) { var self=this;
         arr.each(function (obj) { return self.push(obj) ; }) ;
         self.$.root = root ;
         self.$.keyed = keyed ; } ,
       GET : function (key) { 
        var self=this; { if (self.$.keyed) { return self.find(function (
        obj) { return obj.name() == key ; }) ; } else { return self.at( key) ; } } } ,
       has_key : function (key) { var self=this; { return self.GET( key) ; } } ,
       joinXX : function (other) { var self=this; { if (self.$.keyed) {
         other = other || new EnsoHash ( { } ) ;
         ks = self.keys() || other.keys() ;
         return ks.each(function (k) { return block.call(
           self.GET( k),
           other.GET( k)) ; }) ; } else {
         a = Array( self) ;
         b = Array( other) ;
         return new Range(0, ( [ a.length() , b.length()].max() - 1)).each(function (
          i) { return block.call( a.GET( i), b.GET( i)) ; }) ; } } } ,
       keys : function () { var self=this; { if (self.$.keyed) { return self.map(function (
        o) { return o.name() ; }) ; } else { return null ; } } } })
     load_path = function (path) { return load( System.readJSON( path)) ; }
     load = function (doc) {
       ss0 = make_object( doc, null) ;
       return ss0; return Copy(new ManagedData( ss0), ss0) ; }
     make_object = function (data, root) { if ( data.GET("class") == "Schema") { return makeProxy(
      Schema.new( data, root)) ; } else if ( data.GET("class") == "Class") { return makeProxy(
      Class.new( data, root)) ; } else { return makeProxy(
      MObject.new( data, root)) ; } }
     make_field = function (data, root, keyed) { 
     if ( data.is_a( Array)) { return make_many(
       data,
       root,
       keyed) ; } else { return get_object( data, root) ; } }
     get_object = function (data, root) { if (! data) { return null ; } else if ( data.is_a(
       String)) { return Paths.parse( data).deref( root) ; } else { return make_object(
       data,
       root) ; } }
     make_many = function (data, root, keyed) {
       arr = data.map(function (a) { return get_object( a, root) ; }) ;
       return BootManyField.new( arr, root, keyed) ; }
 Boot = { make_field: make_field };

 x = load_path("/Users/wcook/enso/src/core/system/boot/schema_schema.json");
console.log("x._id = " + x._id()) ;
console.log("Test = " + x.types().to_s());
console.log("Test = " + x.types().GET("Primitive").name()) ;
console.log("Test = " + x.types().GET("Primitive").to_s()) ;
 