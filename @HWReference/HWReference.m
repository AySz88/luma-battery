classdef HWReference < handle
    %HWREFERENCE Reference counting wrapper for the HWSetup singleton
    % This will immediately set up the hardware for you, with default
    % parameters.
    %
    % Usage:
    %    HWRef = HWReference();
    %    hw = HWRef.hw;
    %
    % Note: you MUST hold onto a reference to a HWReference throughout
    % the time you want to use the hardware, or else the HardwareSetup
    % object may get automatically cleaned up!
    %
    % We have to manually do reference counting to get around the fact
    % that MATLAB's default garbage collection will count the presistent
    % variable as a reference.
    
    properties
        hw
    end
    
    methods
        function self = HWReference()
            self.hw = HardwareSetup.instance();
            HWReference.incRefs();
        end
        
        function delete(self)
            HWReference.decRefs();
            if ~HWReference.hasRefs()
                delete(self.hw);
            end
        end
    end
    
    methods(Static, Access=private)
        % Since MATLAB doesn't have Static properties in the typical sense,
        % these functions store the reference count in a persistent
        % variable inside the setGetRefcount function.
        
        function out = setGetRefcount(in)
            persistent refCount;
            if isempty(refCount), refCount = 0; end
            
            if nargin > 0, refCount = in; end
            
            out = refCount;
        end
        function setRefcount(in)
            HWReference.setGetRefcount(in);
        end
        function refs = getRefcount()
            refs = HWReference.setGetRefcount();
        end
        
        function incRefs()
            HWReference.setRefcount(HWReference.getRefcount() + 1);
        end
        function decRefs()
            HWReference.setRefcount(HWReference.getRefcount() - 1);
        end
        function out = hasRefs()
            out = (HWReference.getRefcount() > 0);
        end
    end
    
end

