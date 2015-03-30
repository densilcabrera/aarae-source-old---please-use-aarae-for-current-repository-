# Introduction #
AARAE is a Matlab-hosted environment for measurement, processing and analysis of audio system and acoustic system responses. It is designed to run through a simple graphical user interface, but also to be useable by directly calling particular AARAE functions.
AARAE aims to encourage exploration of measurement and analysis possibilities, rather than only presenting the best or the standard method. Hence easy extensibility is a key feature of AARAE - with only a little additional code, users can drag and drop their own functions into AARAE, so that they add to the exploratory tools accessible through the graphical user interface.

# Authorship and Community #
The initial code infrastructure of AARAE is authored by Densil Cabrera and Daniel Ricardo Jimenez Pinilla. AARAE is intended to be a community project, and we hope that the amount of community-contributed code will grow to be substantially larger than the core infrastructure. Contributors of code retain their own copyright, and contributors are encouraged to use the BSD 3-clause license (which is used for the core code of AARAE).

# Main Concepts #

## Using Matlab for Audio and Acoustic Measurement and Signal Processing ##

In the academic environment, it is very common for Matlab to be used for audio and acoustics measurement and signal processing. Commonly, each researcher or teacher has developed and collected Matlab based tools and techniques, and each has their own way of working. We decided to start the AARAE project partly to organise our Matlab code, to make it easier for others to use, and to facilitate the sharing of code for research and education.

AARAE aims to improve the usefulness and accessibility of Matlab in this context by:
  * providing a graphical user interface to run diverse functions;
  * providing a very useful set of functions for measurement and analysis;
  * allowing functions to be added with relatively little effort;
  * fostering the development of multiple methods and implementations of algorithms to allow comparison and exploration;
  * organising functions into categories;
  * providing for constituent functions to be run either from scripts (or other functions, or from the GUI);
  * keeping track of workflow;

## Open Source  and Extensible ##

While there are many audio and acoustic measurement/analysis tools available, not many are open source. We found problems, limitations and errors using closed source software which, of course, we could not fix because they were closed. Open source software also can have problems, limitations and errors, but these can be fixed and the software can evolve. Open source software also allows a user to inspect the implementation, and so learn from it and/or receive assurance that the implementation is appropriate. This is especially important in education and research.



## Extensible Components ##
AARAE has four categories of functions that can be easily added to by a user:
### Calculators ###
Calculators are implementations of theoretical or empirical models that may be helpful in understanding acoustic or audio systems or processes, but which are not directly concerned with measurement. For example, a calculator could implement an acoustic model of a room, which a user might then compare to measurements made in a real room of the same dimensions.

### Generators ###
Generators are used to generate signals for use in measurement. Examples include generators of swept sinusoids, impulses, noise, STIPA, and so on. A generator can return both a primary and secondary signal (e.g., an inverse sweep for deriving an impulse response from a sinusoidal sweep).

### Processors ###
A processor has audio input and audio output - it is used to modify audio in some way. Filtering and beamforming are examples of processes that are very commonly used in audio and acoustic measurement, but there are many other types of processors that can contribute to exploration.

### Analysers ###
An analyser is primarily concerned with generating a user-readable output, which is typically numeric and/or graphical. There is, perhaps, a grey area between analysers and processors - where a function returns both audio and user-readable results - in which case the code author needs to decide what the best category is.

See the wiki page on [how to write an analyser](https://code.google.com/p/aarae-source/wiki/Analysers).


This page is under construction.