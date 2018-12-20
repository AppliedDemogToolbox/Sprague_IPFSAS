/*** -*-mode:simple-sas-*- **************************************************************
    
    DESCRIPTION: IPF2WAY rakes the data in dataset &DSIN. to the row
        and column controls contained in datasets &ROWCTRLDS. and
        &COLCTRLDS., respectively.  It does so using the two-way rake
        also known as Iterative Proportional Fitting and the RAS
        algorithm.
    
    PROGRAMMERS: webb.sprague@ofm.wa.gov, inspired by Chuck Taylor at
	    the US Census Bureau
    
    DATE STARTED: 2011-08-30

    INPUT (DATASETS, NAMES, ETC): 
		DSIN:        Input dataset 
		VAR:         Variables to be raked
		ROWCTRLDS:   Row control dataset
		ROWCTRLVAR:  Row control variable (single variable: all controls are in one column)
		COLCTRLDS:   Column control dataset
		COLCTRLVAR:  Column control variables

    OUTPUT  (DATASETS, NAMES, ETC): 
		DSOUT:       Output dataset    
		
    NOTES:
	
		2011-08-31 WS (WARNING): This code has only been tested on a
			single set of dummy data (below).  Be careful when
			applying to real data!
	
		2011-08-30 WS (TODO): This macro doesn't have the ID keys
			functionality of the original one.  Have to merge
			horizontally, should add in the future...
	
		2011-08-30 WS (TODO): Needs functionality to set zeros to
			really small numbers (internally defined, I think).
	
		2011-08-30 WS: The algorithm here was coded using Eddie H's
			presentation on IPF. The original inspiration was from the
			Census Bureau (2004-ish), but it didn't work except for
			the stuff to interact with outside datasets.
    
**********************************************************************************/
%macro IPF2WAY(DSIN=,DSOUT=,ROWCTRLDS=,VAR=,ROWCTRLVAR=,COLCTRLDS=,COLCTRLVAR=);	
	proc iml;

		/* tolerance at which to stop iterating -- half a person ... */
		TOL=0.5;		
		
		/* Read in data, row controls, and column controls.  xxxVAR
		 parameters control which columns get fed into the various
		 matrices */
		 
		use &DSIN.; 
		read ALL var {&VAR.} into MATRIX;
		
		use &ROWCTRLDS.; 
		read ALL var {&ROWCTRLVAR.} into ROWCTRL;
		
		use &COLCTRLDS.; 
		read current var {&COLCTRLVAR.} into COLCTRL;
		
		/* use _MATRIX for intermediate and final results, keep original in MATRIX */
		_MATRIX = MATRIX;

		/* Main loop ... */
		/* ...initialize DIFF to large value to force execution of do loop */
		DIFF = 1000;
		/* ... loop until finished. */
		do until (DIFF < TOL);
			_OLDMAT  =  _MATRIX;
			ROWPR    =  _MATRIX / _MATRIX[,+]; /* divide matrix row-wise by rowsum to get controlled proportions*/
			_MATRIX  =  ROWCTRL # ROWPR;	   /* multiply controls by proportion to get numbers*/
			COLPR    =  _MATRIX / _MATRIX[+,]; /* ditto with columns */
			_MATRIX  =  COLCTRL # COLPR;
			DIFF     =  max(abs(_MATRIX - _OLDMAT)); /* check if want to end loop */
		end;
		
		/* output to a new dataset (XXX need to retain key vars for merging but dont - see note.) */
		create &DSOUT. from _MATRIX [colname={&VAR}];
		append from _MATRIX;
	quit;
	
%mend;
	
	 
/*********************************************************************************
   Test code.
**********************************************************************************/
%MACRO _TEST;

	proc sql;
		create table test_dsin (idstr varchar, x1 numeric, x2 numeric, x3 numeric);
		insert into test_dsin values ('foo1', 1, 2, 1);
		insert into test_dsin values ('foo2', 3, 5, 5);
		insert into test_dsin values ('foo3',  6, 2, 2);

		create table test_rowctrlds (rt numeric);
		insert into test_rowctrlds values (5);
		insert into test_rowctrlds values (15);
		insert into test_rowctrlds values (8);

		create table test_colctrlds (ct1 numeric, ct2 numeric, ct3 numeric);		
		insert into test_colctrlds values (11, 9, 8);		
	quit;
	
	%_RAKE2WAYS(DSIN=test_dsin, DSOUT=test_dsout, VAR=x1 x2 x3,
			ROWCTRLDS=test_rowctrlds, ROWCTRLVAR=rt,
			COLCTRLDS=test_colctrlds, COLCTRLVAR=ct1 ct2 ct3);

%MEND;

