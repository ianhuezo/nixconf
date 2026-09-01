final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (pyFinal: pyPrev: {
      pybloomfilter3 = pyPrev.pybloomfilter3.overrideAttrs (oldAttrs: {
        dontCheckPythonMetadata = true;
      });
    })
  ];
}
