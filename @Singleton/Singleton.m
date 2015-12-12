classdef Singleton < handle
   %SINGLETON Abstract Class for Singleton OOP Design Pattern
   %  Intent:  Ensures a class only has one instance and provide a
   %  global point of access to it [1].
   %  Motivation:  It's important for some classes to have exactly one
   %  instance.  For example, it can be desirable to have only a
   %  single instance of a GUI.  With a MATLAB GUIDE built GUI, the driver
   %  or main function provides a global point of access which is
   %  executed to,
   %  1. initially instantiate the GUI; and
   %  2. subsequently bring the existing GUI into focus *not* creating
   %     a new one.
   %  Implementation:  MATLAB OOP doesn't have the notion of static
   %  properties.  Properties become available once the constructor
   %  of the class is invoked.  In the case of the Singleton Pattern, it
   %  is then undesirable to use the constructor as a global point of
   %  access since it creates a new instance before you can check if an
   %  instance already exists.  The solution is to use a persistent
   %  variable within a unique static method instance() which calls the
   %  constructor to create a unique 'singleton' instance.  The persistent
   %  variable can be interrogated prior to object creation and after
   %  object creation to check if the singleton object exists.  There are
   %  two conditions that all subclasses must satisfy:
   %  1. Constructor must be hidden from the user (Access=private).
   %  2. The concrete implementation of instance() must use a persistent
   %     variable to store the unique instance of the subclass.
   % 
   %  Refer to pp.127-134 Gamma et al.[1] for more information on the
   %  Singleton Design Pattern.
   %
   %  Reference:
   %  [1] Gamma, E., Helm, R., Johnson, R. and Vlissides, J.
   %      Design Patterns : Elements of Reusable Object-Oriented Software.
   %      Boston: Addison-Wesley, 1995.

   % Unique properties of Singleton.  This can be only accessed
   % with the getter/setter methods via any subclass of Singleton.
   %properties(Access=private)
   %   singletonData = [];
   %end
   
   methods(Abstract, Static)
      % This method serves as the global point of access in creating a
      % single instance *or* acquiring a reference to the singleton.
      % If the object doesn't exist, create it otherwise return the
      % existing one in persistent memory.
      % Input:
      %    <none>
      % Output:
      %    obj = reference to a persistent instance of the class
      obj = instance();
   end
   
   %{
   methods % Public Access
      % Accessor method for querying the singleton data.
      % Input:
      %   obj = reference to the singleton instance of the subclass
      % Output:
      %   singletonData = internal data store for Singleton object
      function singletonData = getSingletonData(obj)
         singletonData = obj.singletonData;
      end
      
      % Accessor method for modifying the singleton data.
      % Input:
      %   obj = reference to the singleton instance of the subclass
      %   singletonData = new data to set internal data store
      % Output:
      %   <none>
      function setSingletonData(obj, singletonData)
         obj.singletonData = singletonData;
      end
   end
   %}

end

% Based on "Design Pattern: Singleton (Creational)", by B. Nedelkovski
%  http://www.mathworks.com/matlabcentral/fileexchange/24911-design-pattern-singleton-creational
%  The MathWorks Australia Pty Ltd
%  Copyright 2009, The MathWorks, Inc.
%
% Used under BSD license:
%{
Copyright (c) 2009, The MathWorks, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are 
met:

* Redistributions of source code must retain the above copyright 
  notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright 
  notice, this list of conditions and the following disclaimer in 
  the documentation and/or other materials provided with the distribution
* Neither the name of the The MathWorks, Inc. nor the names 
  of its contributors may be used to endorse or promote products derived 
  from this software without specific prior written permission.
      
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.
%}
