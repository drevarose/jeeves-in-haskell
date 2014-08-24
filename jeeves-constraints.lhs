% Style.
\documentclass[letterpaper,11pt,pdftex,envcountsect,envcountsame,envcountswap]{article}
%%
\usepackage{amsmath}
\usepackage[margin=1in]{geometry} % use full page
\usepackage{bibdex}               % Kris' hack to include refs and index in toc.
\usepackage[T1]{fontenc}          % allow bold sans serif
\usepackage{charter}
\bibliographystyle{plain}         % use citations [1], [2], ...
\usepackage[draft]{showlabels}
\usepackage[all]{xy}
\renewcommand{\showlabelfont}{\scriptsize}

\newcommand\lambdaJ{{\ensuremath{\lambda_{\text{J}}}}}

%%  
%% Format.
\input{format}
\makeindex
%% Topmatter.
%%
\title{Constraint Generation for the Jeeves Privacy Language}
\author{Eva Rose\\ Courant Institute, New York University\thanks{This work was conducted whilst at CSAIL, Massachussets Institute of Technology, 2012.} \\ evarose@cs.nyu.edu}
%%
\begin{document}\maketitle
%%
%% End of the Topmatter.

\begin{abstract}\noindent
Our goal is to present a completed, semantic formalization of the Jeeves privacy language evaluation engine, based on the original Jeeves constraint semantics defined by Yang et al at POPL12~\cite{Yang-etal:popl2012}, but sufficiently strong to support a first complete implementation thereof.  
Specifically, we present and implement a syntactically and semantically completed concrete syntax for Jeeves that meets the example criteria given in the paper. 
We also present and implement the associated translation to \lambdaJ, but here formulated by a completed and  decompositional operational semantic formulation.  
Finally, we present  an enhanced and decompositional, non-substitutional operational semantic formulation and implementation of the  \lambdaJ\ evaluation engine (the dynamic semantics) with privacy constraints. In particular, we show  how implementing the constraints can be defined as a monad, and evaluation can be defined as monadic operation on the constraint environment.
The implementations are all completed in Haskell, utilizing its almost one-to-one capability to transparently reflect the underlying semantic reasoning when formalized out way.  
In practice, we have applied the "literate" program facility of Haskell to this report, a feature that enables the source \LaTeX\ to also serve as the source code for the implementation (skipping the report-parts as comment regions). The implementation is published as a github project~\cite{Rose:github2014}.
  
\end{abstract}

\clearpage
\tableofcontents
\clearpage

\section{Introduction}\label{intro}  





Jeeves was first introduced as an (impure) functional (constraint logic) programming language by Yang et al~\cite{Yang-etal:popl2012}, which distinguish itself by allowing \textit{explicit syntax for automatic \ix{privacy enforcement}}.
In other words, the syntax and semantics of the language is designed to support that a  programmer composes privacy policies directly at the source level, 
by way of a special, designated privacy syntax over a not yet known context.
It is worth noticing, that there is \emph{no semantic specification  for Jeeves at the source level}. Jeeves' semantics is entirely defined by a syntax translation to an intermediary constraint functional language, \lambdaJ\ , together with a \lambdaJ\ evaluation engine (defined over the same \ix{input-output function} as source-level Jeeves). In order to run Jeeves with the argued privacy guarantees, it is therefore pivotal to have a correct and running implementation of \lambdaJ\ evaluations as well as a correct  Jeeves-to-\lambdaJ\ syntax-translation, which is the main goal of this report. In Figure~\ref{run-jeeves} we have illustrated how Jeeves' evaluation engine is logistically defined in terms of the \lambdaJ\ language:

\begin{figure}[h]\small
\begin{displaymath}
  \xymatrix{
    &*+[F-]{\text{Jeeves program}} \ar@=[d] ^*\txt{\lambdaJ\ translation}
    \\
    {\text{input}} \ar[r]
    &*+[F-]{\text{\lambdaJ\ program}} \ar[r]
    &{\text{output}}
  }
\end{displaymath}
\caption{Running a Jeeves program}\label{run-jeeves}
\end{figure}


The explicit privacy constructs in Jeeves, and thus \lambdaJ\, is in fact not just syntactic sugar for the underlying conventional semantics, but is interpreted independently in terms of logical constraints on the data access and writes. The runtime generated set of logical constraints that safeguards the policies, are defined as part of the usual dynamic and static semantics. As we  show with our re-formalization of the dynamic semantics, the constraint part of the semantics can in fact be defined as a  monoid, thus following an othogonal evaluation pattern with respect to the underlying traditional evaluation semantics. An observation which not only makes it straighforward to implement, but makes privacy leak arguments straight forward to express and proof.






In this report, we have re-stated the original formalizations of the abstract syntax for source-level Jeeves, as well as for \lambdaJ\ , by way of algebraic and denotational (domain) specifications. As a new thing, we have added a concrete syntax for source-level Jeeves as an LL(1) grammar, along which we have re-adjusted the \lambdaJ\ compilation to be specified as a syntax-directed translation.  Furthermore, we are re-formulating the definition of the dynamic (evaluation) semantics by way of operational (natural) semantics.  In the process, we have added a number of technical clarifying details and assumptions, as summarized in section~\ref{impldesign}. Notably, we have imposed a formal (denotational) definition of a Jeeves aka \lambdaJ\ "\emph{program}", and semantically specified how programs should be evaluated at the top level . We should mention, that the treatment of types (and the associated static semantics) has been omitted, thus leaving it to the user not to evaluate ill-formed terms or recursively defined policies. 


The implementation has been conducted in Haskell. Using that specific functional language, provides a particular elegant and one-to-one imlementation map of the denotational and operational specifications of  Jeeves, aka \lambdaJ\ . In fact, by having implemented the dynamic, operational semantics of \lambdaJ\ , we have obtained a Jeeves/ \lambdaJ\  interpreter. To implement the parser, we in fact used the Haskell monadic parser combinator library~\cite{HuttonMeijer:jfp1998}, which has been included in full in Appendix~\ref{parserframework}. One limitation with the current implementation, however, is that we have not included a constraint solver, but merely outputs all constraints to be further analysed. It is, however, a minor technical detail to add an off-the-shelf constraint solver to the backend.  

 The presentation of the implementation in the report, has been done by using the \emph{literate programming facility} of Haskell, as described in  Notation~\ref{literatehs}. En bref, it permits us to use the source \LaTeX\ of the report as the source code of the program.
In the report, we have  preceded each code fragments with the formalism it implements, so that the elegant, one-to-one correspondance between the formalism and the Haskell program serves as a convincing argument for the authenticity of the Jeeves implementation (and vice versa, in that the running program fragments support the formalizations). To ease readability we have furthermore been typesetting and color coding the Haskell implementation, also summarized in Notation~\ref{literatehs}. 

\begin{notation}[The Haskell implementation]\leavevmode\label{literatehs}
The Haskell program has been integrated with the report as specially designated \textbf{Haskell} sections by means of the literate programming facility for Haskell~\cite{haskell10}. This facility (file extension .lhs), enables Haskell code and text to be intertwined, yet percieved either as program (like .hs extension) with text segments appearing as comments, or as a TeX report (like the .tex extension)  where code fragments appear as text. All depending on which command is run upon the ensemble.

For convenience, the typesetting of the Haskell sections uses coloring for emphasis and prints the character sequences
shown in the following table as special characters.
\begin{displaymath}
\begin{array}{|l|c|c|c|c|c|c|c|c|c|c|c|}
\hline
\text{Symbol used in report} &{\lambda}&{+\!+}&{\rightarrow}&{\leftarrow}&{\Rightarrow}&{\leq}&{\geq}&{\equiv}&{\circ}&{\gg}&{\gg\!=} \\
\hline
\text{Haskell source form} &\texttt{\char92}&\texttt{++}&\texttt{->}&\texttt{<-}&\texttt{=>}&\texttt{<=}&\texttt{>=}&\texttt{==}&\texttt{.}&\texttt{>{}>}&\texttt{>{}>=} \\
\hline
\end{array}
\end{displaymath}
\end{notation}

Before we proceed, we will introduce the literate Haskell programming head. 

\begin{haskell}[main program and imports]\leavevmode
\begin{code}

-------------------------------------------------------
-- Evaluates Jeeves programs and generates policy constraints
-- Eva Rose <evarose@mit.edu>
-- CSAIL August 2012.
-------------------------------------------------------

-- Imported data types
import Data.Map (Map,(!),insert,delete,empty,union,member,assocs)
import Char

\end{code}
\end{haskell}


The semantic and syntactic specification styles follow those of Plotkin~\cite{Plotkin:daimi1981}, Kahn~\cite{Kahn:stacs1987}, Schmidt~\cite{Schmidt:1986}, Bachus and Naur~\cite{Naur:algol60}, alongside  the formal abbreviations, shorthands and stylistic elements which we have summarized in Notation~\ref{note}.

\begin{notation}[Formal style summary]\leavevmode\label{note}
We have adopted the following conventions:
\begin{itemize}
  \item the shorthand '$Sym~\cdots~Sym$' to denote a finite repetition of the pattern $Sym$, one or more times,
  \item the \texttt{teletype} font for keywords in source-level Jeeves, and $\kw{sans serif}$ for keywords in \lambdaJ.
\end{itemize}
\end{notation}

Before we describe how the report is structured we will recall, with two examples from the original paper, what programming with Jeeves looks like. The first being a simple naming policy example, and the second having to do with the tasks involved in accessing and managing papers for a scientific conference. Both will serve as our canonical examples throughout the report.
 
\begin{example}[\ix{Canonical examples}]\leavevmode\label{confmanage}
Figure~\ref{fig:testp1} and Figure~\ref{fig:testp2} consist of two Jeeves programming examples from Sec.~2.2 in~\cite[p.87]{Yang-etal:popl2012}, but  
as slightly altered versions. Among other things, we have fixed the format of a Jeeves program c.f. Definition~\ref{def:jeeves-abs-syn}. Furthermore, we have changed the examples in the following ways:
\begin{itemize}
\item tacitly omitted 'reviews' from the 'paper' record and from the policy definitions, as dealing with 
listings just introduce "noise" to the presentation without adding any significant insight,
\item only to allow policies on the form  "\texttt{policy}~lx \texttt{:} e \texttt{then}  lv \texttt{in} e"; we have thus moderated 
the original examples by adding "\texttt{in} p" to those policy definitions were the keyword "in" was missing,
\item omitted types in accordance with our design decisions.
\end{itemize}


\begin{figure}[h]\small
\verbatiminput{Tests/testp1.jeeves}
\vspace*{-2em}
\caption{Naming policy}\label{fig:testp1}
\end{figure}

The program in Figure~\ref{fig:testp1} overall introduces a policy (`\textit{policy\dots: !(context="alice")}\dots') which regulates what value the variable `\textit{name}' is assigned: either to `\texttt{"Anonymous"}' or to `\texttt{"Alice"}'. Let us first hone in on the (first order) logical policy condition `\textit{!(context="alice")}'. This is simply a boolean expression stating to be true if the value of the designated, built-in variable `\textit{context}' is different from the  string `\texttt{"alice"}', otherwise false. (The `\texttt{!}' stands for negation.)  In the first case, `\texttt{bottom}' will select the first value of the pair `\texttt{<"Anonymous","Alice">}', whereas in the latter case, the second value will be chosen to be assigned to `\texttt{name}'. Now hone in on the print-statements at the bottom of the program. The semantics tells that the `\textit{context}' variable first is automatically set to the string `\texttt{"alice"}' (by the `\texttt{print \{"alice"\}}\dots' statement); subsequently to the string `\texttt{"bob"}' (by the `\texttt{print \{"bob"\}}\dots' statement). These print-statements are also the ones responsible for the program output by printing the value of the variable `\texttt{msg}', which in turn is designated by the values of `\texttt{name}' (by the '\texttt{let msg = ... name}' statement). In other words, the input-output functionality is given by the print statements. Thus, upon the input: `\texttt{alice}' `\texttt{bob}', the expected output of this program is: `\texttt{Author is Alice}' `\texttt{Author is Anonymous}'.


\begin{figure}[p]\small
\verbatiminput{Tests/testp2.jeeves}
\caption{Conference management policies}\label{fig:testp2}
\end{figure}

The program in Figure~\ref{fig:testp2} overall introduces policies for managing access to conference papers, depending upon the formal role a person possesses. The policies to avoid leaking the name of a paper author at the wrong time in the review process, follows the basic principle of the naming policy in Figure~\ref{fig:testp1}, just in a more complex setting. The first let-statement of the program creates a paper record through the function `\texttt{mkpaper}' with information on `\texttt{title}', `\texttt{author}', and `\texttt{accepted}' status. By way of the level variables `\texttt{tp}', `\texttt{authp}', and `\texttt{accp}', three leak policies are being added as conditioned values, each of which is being defined by the subsequent let-statements. Take for example the first of these: `\texttt{addTitlePolicy p tp;}'. The policy states that if a viewer is not the author, and the viewer's role is neither that of a reviewer's or program chair, and finally, if not the review process is over (the stage is then then `\texttt{public}') or the paper has been accepted, then the title can only be released as \texttt{""} (because the `\texttt{bottom}' value selects the first of the title pair values in `\textit{mkpaper}', which is \texttt{""}). Similarly for the other policy specifications. The next set of let specifications set the variables `\texttt{alice}' and `\texttt{bob}' with concrete review records, and the two boolean functions `\texttt{isAuthor}' and `\texttt{isAccepted}' are similarly set with concrete boolean expressions. Also here, the print-statements are responsible for assigning the `\texttt{context}' variable with concrete viewer and stage information, and to output a record corresponding to a paper, through a call to "\textit{mkpaper}", where the individual paper fields have been filtered by the specified policies. 

\end{example}


We assume that the reader of this report is familiar with the core principles of the original Jeeves definition in Yang et al~\cite{Yang-etal:popl2012}. Furthermore, we assume an understanding of functional programming in Haskell~\cite{haskell10,hutton2007programming}, as well as basic familiarity with algebraic specifications and semantics~\cite{Naur:algol60,Kahn:stacs1987,Plotkin:daimi1981,Schmidt:1986}.   

Finally, we describe how the report is structured:                                                           
                                                                                                                      
\begin{itemize}
\item In Sec.~\ref{jeevesconcrsyntax}, (source-level) Jeeves is specified both by its abstract as well as a newly formulated concrete syntax. The concrete syntax is specified in terms of an LL(1) grammar along with the lexical tokens for Jeeves and their implementation in Haskell.
\item In Sec.~\ref{lamjabssyntax}, (intermediary) \lambdaJ\ is specified by its abstract syntax alongside its implementation in Haskell. Notably, the notion of a \lambdaJ\ program  has been added to the original syntax together with additional expression syntax (thunks). The ensemble is presented alongside its implementation in Haskell.
\item In Sec.~\ref{lamjtrans}, we formally present the translation from Jeeves to \lambdaJ\ as a derivation. The translation is given as a syntax directed compilation of the concrete Jeeves syntax to \lambdaJ, together with its Haskell implementation. The implementation is in fact a set of Jeeves parsers, which builds abstract syntax trees in accordance with the abstract \lambdaJ specification in Section~\ref{lamjabssyntax}.
\item In Sec.~\ref{lamjval}, we  formally present the symbolic normal forms with the addition of a static binding environment component. The implementation of those are  presented together with operations on the environment, notably insertion and lookups.
\item In Sec.~\ref{ref:constraints},  we specify the notion of a hard constraint algebra, and soft constraint algebra as well as the notion of a path condition algebra. We finally show how the set of hard and soft constraints can be implemented as a monad in Haskell, together with update and reset operations thereon.  
\item In Sec.~\ref{jeval}, the \lambdaJ\ evaluation engine is formally specified as a  big step, compositional, non-substitution based  operational semantics alongside our specification of a \lambdaJ program evaluation. The Haskell implementation in terms of a \lambdaJ interpreter is presented alongside the formalizations. The input-output functionality is equally specified, and a program outcome is defined in our setting as a series of "effects" written to output channels.    
\item In Sec.~\ref{runjeeves}, we show how to load and run a jeeves program with our system, as well as how to use our system to translate a Jeeves program to \lambdaJ.
\item Finally, in section~\ref{concl}, we conclude our work, and discuss further directions in section~\ref{futurama}.
\end{itemize}

We will describe in which way our formalizations deviates from the original formulations \cf Yang et al~\cite{Yang-etal:popl2012} as we go along, and summarize the discrepancies in Appendix~\ref{impldesign}.


\section{The Jeeves syntax}\label{jeevesconcrsyntax}


In this section, we restate the \ix{Jeeves abstract syntax} from the original paper~\cite[Figure~1]{Yang-etal:popl2012}, and a (new) formulation of a \ix{Jeeves concrete syntax}. We also specify the basic algebraic sorts for literals that are assumed by the specifications, and present them as \ix{Jeeves lexical tokens} for the \lambdaJ\ translation in subsequent sections. The syntax specifications include some language restrictions and modifications 
compared to the original rendering in accordance with section~\ref{impldesign}. %%% and remark~\ref{Jevlangrestrict}. 
Notably, restrictions on the shape of a \ix{Jeeves program}, such that all \texttt{let}-statements (\ie, \texttt{let} constructs without an \texttt{in}-part) must be trailed by \texttt{print}-statements, and both are only to appear at the top-level of the program. 
  
The abstract syntax merely serves as a quick guide to the Jeeves language just as in the original form~\cite[Figure~1]{Yang-etal:popl2012}. It is presented as a complete, algebraic specification which describes Jeeves programs, expressions, and tokens in a top-down fashion, following Notation~\ref{note}. 
The concrete syntax for source-level Jeeves has been formulated as an (unambiguous) LL(1) grammar from scratch. Thereby making it straightforward to apply the  \ix{Haskell monadic parser combinator library}~\cite{HuttonMeijer:jfp1998} when implementing the \lambdaJ\ translation function in subsequent sections. The syntax 
precisely states the way operator precedence and scoping is being handled, if not by the original specification~\cite[Figure~1]{Yang-etal:popl2012}, then by the original Jeeves program examples~\cite[Section~2]{Yang-etal:popl2012} (for more details on discrepancies and differences, visit section~\ref{impldesign}S).   


The only Haskell implementation in this section is that of the Jeeves lexical tokens in Haskell~\ref{hs:litlextok}.

 
\begin{definition}[abstract Jeeves syntax]\label{def:jeeves-abs-syn}
\begin{align*}
p \in Pgm~:: = ~ & {\begin{aligned}[t]
              & ~ \texttt{let}~ x \, \dots \, x\,\texttt{=}\,e \\[-2\jot]
              & ~ \vdots \\[-\jot]
              & ~ \texttt{let}~ x \,\dots\, x\,\texttt{=}\,e \\
              & ~ \texttt{output} ~ \texttt{{} e \texttt{}}~ e \\[-2\jot]               
              & ~ \vdots \\[-\jot]
              & ~ \texttt{output} ~ \texttt{{} e \texttt{}}~ e                            
\end{aligned}}
\\
e \in Exp~:: = ~ & {\begin{aligned}[t]
             & b~|~n~|~s~|~c~|~x~|~lx~|~\texttt{context} 
\\
          | ~ & ~ e ~op~ e ~|~ uop~e
\\
          | ~ & ~\texttt{if}~e~\texttt{then}~e~\texttt{else}~e
\\
         ~|~& ~ e \, \dots \, e
\\
         ~|~& ~ \texttt{<}\, e \,    \texttt{|}  e \,\texttt{>}\,\texttt{(}lx\texttt{)} 
\\
         ~|~& ~ \texttt{level}~ lx \texttt{,} \dots \texttt{,}\, lx  ~\texttt{in} ~ e                   
\\
         ~|~& ~ \texttt{policy}~ lx\, \texttt{:} \, e ~ \texttt{then} ~ lv ~\texttt{in}~ e
\\
         ~|~& ~\texttt{let}~ x\, \dots x \,\texttt{=}\, e ~\texttt{in}~ e
\\
         ~|~& ~ \texttt{\{} x \, \texttt{=} \, e \texttt{;}\dots\texttt{;} x \, \texttt{=} \, e ~\texttt{\}}
\\
         ~|~& ~ e\texttt{.}x
\\
         ~|~& ~ e \texttt{;}~ \dots\texttt{;} e           
\end{aligned}}
\\[-2\jot]
\\
\text{where}~ b \in Boolean, ~ & n \in Natural, ~ s \in String, ~  c \in Constant, \\
      \text{and} ~  lx, x \in Identifier, ~ & lv \in Level, ~ op \in Op, ~ uop \in UOp  ,~ \texttt{output} \in Outputkind 
\end{align*}
\end{definition}

The where-clause lists the basic value sorts of the language. They cover the same algebras in source-level Jeeves and the \lambdaJ\ level, except for $Level$,
 which only exists in the source-level language. 
For that reason, we will duplicate the formal (meta) variables between the abstract and concrete syntax and between source and target language
 specifications. In  Definition~\ref{litlextok}, they are specified as concrete, lexical tokens.

\begin{definition}[\ix{basic algebraic sorts}]\label{def:base-sorts} 
 The sorts are $Boolean$ for truth values, $Natural$ for natural numbers, $String$ 
for text strings, $Constant$ for constants, and $Identifier$   
for variables. The $Level$ sort denotes public vs.\ private confidentiality levels (originally formalized by `$\top$' vs `$\bot$'),
 the $Op$ sort denotes binary operations, and $UOp$ denotes unary operations. The $Outputkind$ sort 
denotes the different channelings of output, here limited to \texttt{print} or \texttt{sendmail}.
\end{definition}

\begin{notation}[\ix{Identifier naming conventions}]\label{identkinds}\leavevmode
We use  $x$ to denote a \ix{regular variable}, and  $lx$ to denote a \ix{level variable}.
\end{notation}

The concrete syntax description is specified in (extended) Backus-Naur form,  with regular
expressions for the tokens~\cite{Naur:algol60}. In order to ease the implementation of the Jeeves parser, we have 
specifically formulated the concrete syntax as an LL(1) grammar,\footnote{LL(1) grammars are context-free 
and parsable by LL(1) parsers: input is parsed from left to right, constructing a leftmost derivation of the sentence, using 1 lookahead token to 
decide on which production rule to proceed with.} because of the then direct applicability of the \ix{Haskell monadic parser combinator library}~\cite{HuttonMeijer:jfp1998}. 

\begin{definition}[concrete Jeeves syntax]\label{def:jeeves-concr-syn}
\begin{align*}
    p \tag{Program} ::&= lst^* ~ pst^*     
\\
    lst \tag{LetStatement} ::&= ~ \texttt{let} ~ x ~ x^*~\texttt{=}~ e \\
    pst \tag{OutputStatement} ::&= ~ \texttt{output} ~ \texttt{\{} e \texttt{\}} ~ e 
\\
e \tag{Expression} :: & = ~ lie~|~lie\,\texttt{;}~e ~|~\texttt{if}~e~\texttt{then}~e~\texttt{else}~e ~|~ \texttt{let}~ x ~ x^*\, \texttt{=} \, e ~\texttt{in}~ e  \\[-\jot] %% OBSOLETE~ \texttt{lambda}\, x \, \texttt{.} \, e
                       &\quad|~ \texttt{level}~ lx\,(\texttt{,}~lx)^* ~\texttt{in} ~ e
                       ~|~ \texttt{policy}~lx \, \texttt{:} \, e ~ \texttt{then} ~ lv ~\texttt{in} ~ e \\
    lie \tag{LogicalImplyExpression} :: & = loe ~\boldmath{\Rightarrow}~ loe ~|~ loe \\
    loe \tag{LogicalOrExpression} :: & = loe ~\texttt{||}~ lae ~|~ lae \\
    lae \tag{LogicalAndExpression} ::& = lae ~\texttt{\&\&}~ ce ~|~ ce \\
    ce \tag{ComparisonExpression} :: &= ae ~\texttt{=}~ ae ~|~ ae ~\texttt{>}~ ae ~|~ ae ~\texttt{<}~ ae ~|~ ae \\
    ae \tag{AdditiveExpression} :: &= ae + f\!e ~|~ ae - f\!e ~|~ f\!e \\  %% must be left associative: a-b-c = (a-b)-c
    f\!e \tag{FunctionExpression} :: &= f\!e ~ pe ~|~ pe \\  %% currying!  f x y = (f x) y
    pe \tag{PrimaryExpression} :: &= ~lit ~|~ x  ~|~ \texttt{context} \\
                                & ~| ~ \texttt{<}ae\texttt{|}ae\texttt{>}\,\texttt{(}lx\texttt{)} ~|~ rec ~|~ pe \texttt{.} x ~| ~ \texttt{!} pe ~|~ \texttt{(} e \texttt{)} \\[-\jot]
    lit \tag{Literal} :: &= b ~|~ n ~|~ s ~|~ c \\
    rec \tag{Record} :: &= \texttt{\{}\,xe\,(\texttt{;}~xe)^*\, \texttt{\}} ~|~ \texttt{\{\}} \\
    xe \tag{Field}  ::&= ~ x ~\texttt{=}~ pe 
\\[-2\jot]
\\
\text{where}~ b \in Boolean, ~ n & \in Natural, ~ s \in String, ~  c \in Constant, \\
      \text{and} ~  lx, x \in Identifier,   ~ & lv \in Level, ~ op \in Op, ~ uop \in UOp, ~ \texttt{output} \in Outputkind 
\end{align*}
\end{definition}

To simplify where potential \ix{privacy leaks} may appear in a program, we restrict the Jeeves language semantics by imposing a number of simple restrictions.
Notably, that statements are only allowed at the top-level of a program.
There are two types of (source-level) Jeeves statements: simple \texttt{let} statements that define the global, recursively defined binding environment,  
and the \texttt{output} statements, that induce (output) side effects. Because (output) \ix{side effects} represent potential privacy leaks, we have simplified 
matters by only allowing output statements to be stated at the end of a program, thus textually after the global binding environment has been established. Even though this is simply a syntactic decision, it supports a programmer's intuition  when to let the semantics apply in this way. 
By only allowing recursion to appear at the top-level of a Jeeves program, we hereby simplify how and where policy (constraint) side effects can appear, in accordance with a programmer's view.

We proceed by specifying the basic algebraic sorts from Definition~\ref{def:base-sorts}, as concrete \ix{lexical tokens}, together with their implementation in Haskell~\ref{hs:litlextok}. 


\begin{definition}[Jeeves lexical tokens]\label{litlextok}
\begin{align*}
  b \tag{Boolean} & ::= \texttt{true} ~|~ \texttt{false} \\
  n \tag{Natural} & ::= \text{[0-9]}^+ \\  
  s \tag{String} & ::= \texttt{"}~ \text{[}\lnot\texttt{"}\nl\text{]}^* ~ \texttt{"} \\
  c \tag{Constant} & ::= \text{[A-Z]} ~ \text{[A-Za-z0-9]}^* \\
  lx,\,x \tag{Identifier} & ::= \text{[a-z]} ~ \text{[A-Za-z0-9]}^* \\
  lv \tag{Level}  & ::= \texttt{top} ~|~ \texttt{bottom} \\
  op \tag{BinaryOp} & ::=  \texttt{+}  ~|~ \texttt{-}  ~|~ \texttt{<} ~|~ \texttt{>} ~|~  \texttt{=}  ~|~ \texttt{\&\&} ~|~  \texttt{||} ~|~ \texttt{=>} \\
  uop \tag{UnaryOp} & ::=  \texttt{!} \\
  \texttt{output} \tag{Outputkind} & ::= \texttt{print}~|~ \texttt{sendmail} 
\end{align*}
\end{definition}


\begin{haskell}[Jeeves lexical tokens]\label{hs:litlextok}
Lexical tokens are straight forwardly implemented as Haskell literals.
Boolean and String literals are predefined in Haskell. Other literals are mapped to Haskell's Integer and String types.

\begin{code}
type Natural     = Integer 
type Constant    = String
type Identifier  = String
type Level       = String
type BinaryOp    = String
type UnaryOp     = String
type Outputkind  = String
\end{code}
\end{haskell}

\begin{remark}
The implementation of Constant, Identifier, Level, BinaryOp, UnaryOp, and Outputkind does not really reflect the restrictions imposed by the regular expression definition in Definition~\ref{litlextok}. For example, by allowing constants or identifiers to start with a digit. We will instead address these restrictions by the (error) semantics.
\end{remark}


Finally, we will re-visit the first of our canonical examples, the enforcement of a naming policy, from Example~\ref{confmanage}.
The goal is to informally explain the overall syntactic structure of a simple Jeeves program, as a stepping stone to familiarize a programmer with the language. 


\begin{example}[Jeeves name policy program]\leavevmode\label{ntp}
\begin{verbatim}
1. let name =  
2.  level a in
3.     policy a: !(context = alice) then bottom in < "Anonymous" | "Alice" >(a)

4. let msg = "Author is " + name

5. print {alice} msg
6. print {bob} msg

\end{verbatim}
This program begins with a sequence of let-statements (`\texttt{let name}\dots', and `\texttt{let msg}\dots'), trailed by a sequence of print-statements 
(`\texttt{print {alice} msg}', and `\texttt{print {bob} msg}'). We expect the let-statements in line 1 and 4, by means of the underlying semantics, to set up a global (and recursively) defined binding environment (which we shall express as [`\texttt{name}'~$\rightarrow$~\dots; `\texttt{msg}'~$\rightarrow$~\dots ] in accordance with tradition). It is the print-statements, however, which are causing side effects in terms of printing the values of `\texttt{msg}' in line 5 and 6. We notice that the build-up of constraints by the `\texttt{level a in policy a:}\dots' expression in line 2 and 3, is tacitly expected to be resolved by the semantics.  
 The program captures in many ways the essence of Jeeves' unique capability to "filter" a program outcome: a naming policy, associated with the level variable `\texttt{a}', is explicitly defined in terms of a  predicate `\texttt{n!(context = alice)}' in line 3 (`!' stands for negation), where `\texttt{context}' is a keyword for the implicit, designated input variable that gets set by the print statements in line 5 and 6. The value of the predicate will in turn decide how the \ix{sensitive value} `\texttt{<"Anonymous"|"Alice">}' evaluates to either `\texttt{"Anonymous"}' or `\texttt{"Alice"}'. The final outcome  
results in `\texttt{msg}' being assigned in line 4 to the result of the policy expression evaluation. To summarize, we have that the \ix{input-output function} is uniquely given by the print-statements in line 5 and 6. \emph{The input} is read from  the expression,  stated between the `\texttt{\{}' and the `\texttt{\}}', and assigned the designated '\texttt{context}' variable (here, `\texttt{alice}' and `\texttt{bob}'). \emph{The output} by the two print statements, however, is given by the expression trailing the curley braces (here, `\texttt{msg}'). For further details on the meaning of this example, we refer to Example~\ref{confmanage}.      
\end{example}

In Sec.~\ref{runjeeves}, we show how to run this program with the system developed in this report.  



\section{The {\lambdaJ} syntax}\label{lamjabssyntax}


In this section, we re-state the \ix{\lambdaJ\ abstract syntax} from the original paper~\cite[Figure~2]{Yang-etal:popl2012}, adding a (new) formulation of a  \ix{\lambdaJ\ program}, along a (new) type of expression (\ix{thunks}). We specify \lambdaJ\ programs, statements, and expressions algebraically in a top-down manner, following the  stylistic guidelines in Notation~\ref{note}. We do, however, redefine the notion of a  \lambdaJ\ value to be a property over the expression sort, and the \kw{error} primitive to be redefined from a syntactic value to  a semantic entity.  Finally, the \kw{error} primitive is redefined from a syntactic value 
to  a semantic entity, and the \kw{()} (unit) primitive is removed completely as a value.\footnote{The unit primitive only appears in the E-ASSERT 
rule in~\cite[Figure~3]{Yang-etal:popl2012}, hiding the fact that the Jeeves translation only generates \texttt{assert} expressions which include an 
"\kw{in}~e" part~\cite[Figure~6]{Yang-etal:popl2012}. Thus eliminating the need for a unit.} %% Better explanation?
All which is necessary to maintain the role of  \lambdaJ\ as an intermediary language for Jeeves. The ensemble has been implemented in Haskell with code shown  alongside the presentation of the concepts. The Haskell implementation  of \lambdaJ\ is designed as a one-to-one mapping from the \lambdaJ\ syntax algebras to Haskell data types, where the basic algebraic sorts and the formal (meta) variables remain shared between the Jeeves and \lambdaJ level, as specified in previous sections.



First, we define our notion of a \ix{{\lambdaJ} program} `$p$'. It is specified as a list of mutually recursive (function) bindings `$ x \,\kw{=}\,ve \dots x \,\kw{=}\,ve$' that constitutes the static environment  for evaluating the $\texttt{output}$ statements `$s~\dots~s$'. (It is the `\kw{letrec}', which semantically specifies the recursive nature of the bindings by its traditional meaning~\cite{H80:FunctionalP}.) The $Statement$, $Exp$, and $ValExp$ algebraic sorts are all being defined later in this section. 







\begin{definition}[abstract \lambdaJ\ program syntax]\label{lamjpgm}
\begin{align*}
p \in Program  ::= ~ & {\begin{aligned}[t]
              \kw{letrec} ~ &   \\[-2\jot] 
                            & ~ x  \kw{=}\,ve \, \dots \, x \kw{=}\,ve \\[-2\jot] 
              \kw{in} ~ &  \\[-2\jot] 
                        & ~  s ~ \dots ~ s \\[-2\jot]
                      \end{aligned}}
\\[-2\jot]
\\
\text{where}  ~ x \in Identifier, ~ ve \in ValExp, & ~ s \in Statement, \text{and} ~ ValExp \subseteq Exp 
\end{align*}
 The list of bindings, $\,x \,\kw{=}\,ve \dots x \,\kw{=}\,ve$, and statements, $\,s\,\dots\,s$, are auxiliary  algebraic sorts. 
\end{definition}

This definition has a straight forward implementation is Haskell:

\begin{haskell}[abstract {\lambdaJ\ program syntax}]\leavevmode\label{hs:lamjpgm}
A program is implemented in terms of a combinator \textsf{Bindings}, and \textsf{Statements} data type. 
The letrec-defined environment is specifically implemented by the \textsf{Binding} list data type. 

\begin{code}
data Program = P_LETREC Bindings Statements deriving (Ord,Eq)

type Bindings    = [Binding] 
data Binding     = BIND Var Exp deriving (Ord,Eq)  
\end{code}
\end{haskell}

The $Statement$ sort is defined as specified in the original paper~\cite[Figure~2]{Yang-etal:popl2012}, followed by is straight forward implementation:

\begin{definition}[abstract \lambdaJ\ statement syntax]\label{lamjstat}
\begin{align*}
s \in Statement   ::= & {\begin{aligned}[t]
              ~ \kw{output} ~  (\kw{concretize}\,  e \, \kw{with} \, e ) \\[-2\jot]
                 \end{aligned}}
\\[-2\jot]
\\
\text{where}  ~ e \in Exp, ~ \kw{output} & \in Outputkind
\end{align*}
\end{definition}


\begin{haskell}[abstract {\lambdaJ\ statement syntax}]\leavevmode\label{hs:lamjstm}
The list of statements is straight forwardly implemented by the \textsf{Statements} list data type. 

\begin{code}
type Statements  = [Statement] 
data Statement   = CONCRETIZE_WITH Outputkind Exp Exp deriving (Ord,Eq)   
\end{code}
\end{haskell}

 
We wish to address the issue of our introduction of \kw{thunk}s, and thereby our need for introducing the sub-sort $ValExp$ of $Exp$ in 
Definition~\ref{valexp}.
Let us for a moment side-step the fact that the letrec-bindings in Definition~\ref{lamjpgm} only are allowed to happen to value expressions (`$x=ve$') when
the static \ix{binding environment} is established, and instead assume that bindings are allowed to happen over all expressions (`$x=e$') as defined in Definiton~\ref{lamjexp}. Because Jeeves, and whence \lambdaJ, is defined to be an \ix{eager language}, parsing of an expression `$e$', however, may cause significant, unintended  behaviour at binding time, 
as illustrated by the following \lambdaJ\ program:
\begin{align*}
  & {\begin{aligned}[t]
              \kw{letrec} ~ &   ~ x  ~ \kw{=} ~  (ack ~ 100) ~ 100  \\
              \kw{in} ~ &  \kw{print} \, (\kw{concretize}\,  5 \, \kw{with} \, 5 ) 
                      \end{aligned}}
\end{align*}
 This program binds `$x$' to an instance of the \ix{Ackermann function}, even though it clearly outputs the number $5$, regardless of the value of $(ack ~100)~ 100$! The problem is 
that Ackermann with those arguments is a number of magnitude $10^{20000}$ digits!\footnote{In comparison, the estimated age of the earth is approximately $10^{17}$ seconds.}  An eager language will cause this enormous number to be calculated at binding time, leading to a halt before any print statement has 
been evaluated.

The established manner to handle scope is to introduce `\ix{\kw{thunks}}' as a way of "wrapping up" undesired expressions with a syntactic containment annotation. Thereby allowing binding resolution to be delayed until the correct scope is established. Precisely as prohibiting "evaluation under lamba" is a common way of "wrapping up" function evaluation. Technically, to put it on \emph{\ix{weak head normal form}}.

Because the original \lambdaJ syntax does not allow this, we have extended the expression sort with `$thunk~e$', and created a special subsort $ValExp$ which contains expressions on  \emph{weak head normal form}. These features will in particular show up as useful features when specifying and implementing the \lambdaJ\ translation. A correct version of the above program hereafter is:
\begin{align*}
  & {\begin{aligned}[t]
              \kw{letrec} ~ &   ~ x  ~ \kw{=} ~  \kw{thunk}\, ((ack ~ 100) ~ 100) \\
              \kw{in} ~ &  \kw{print} \, (\kw{concretize}\,  5 \, \kw{with} \, 5 ) 
                      \end{aligned}}
\end{align*}



We proceed by restating the abstract syntax according to the discussed considerations.

\begin{definition}[abstract {\lambdaJ} expression syntax]\label{lamjexp}
\begin{align*}
     e \in Exp :: &= ~b~|~n~|~s~|~c~|~ x~|~lx~ |~ \kw{context}   %% fjernes, da ej genereres af pars: ~|~ \kw{error} ~|~ \kw{()}
\\
                  & ~|~ \lambda x \kw{.} e ~|~  \kw{thunk} \,e       
\\
                  & ~|~ e~op~e ~|~ uop~e 
\\
                  & ~|~ \kw{if}~e~\kw{then}~e~\kw{else}~e
\\
                  & ~|~ e~e                  
\\
                  & ~|~ \kw{defer}~lx~\kw{in}~e
\\
                  & ~|~ \kw{assert}~e~\kw{in}~e 
\\
                  & ~|~ \kw{let}~x=e~\kw{in}~e 
\\
                  & ~|~ \kw{record}~fi{:}e \,\cdots\, fi{:}e  
\\
                  & ~|~ e\kw{.}fi
\\[-2\jot]
\\
\text{where}~ b \in Boolean, ~ & n \in Natural, ~ s \in String, ~  c \in Constant, \\
      \text{and} ~  op \in Op, ~ up \in UOp, ~ & lx, x \in Var, ~  fi\in FieldName
\end{align*}
Here, we have tacitly assume that the  $Identifier$ sort has been partitioned into two separate namespaces:  
$lx,\,x\in Var$, and $fi\in FieldName$, with the obvious meaning.
\end{definition}



\begin{remark}[empty expression]\leavevmode\label{rem:if-sensi}
 The empty record is represented by the keyword \kw{record}.
\end{remark}

\begin{remark}[\kw{defer} expression]\leavevmode\label{rem:defer}
The original defer expression syntax come in two forms (with types omitted): `$\kw{defer}\, lx\, \{ e \}\, \kw{default}\, \upsilon$' and `$let\,l=\kw{defer}\, lx\, \kw{default}\, \kw{true}\, \upsilon\, \kw{in}\, e$'  in Yang et al~\cite[Figure~2,\textsc{e-defer}]{Yang-etal:popl2012} and~\cite[Figure~6,(\textsc{tr-level})]{Yang-etal:popl2012} respectively.
The version we have chosen to formalize, is a modification in a couple of ways yet preserving the intended translation semantics.
First, the `$\kw{default}\, \kw{true}$' part is omitted from the syntax, because this contribution from the 
Jeeves translation is so trivial that it can be dealt with by the evaluation semantics instead \cf Definition~\ref{evaldefer}.
Second, the contribution from `$\{ e \}$' is none according to Yang et al~\cite[Figure~6,(\textsc{tr-level})]{Yang-etal:popl2012}.
Thus, we have allowed a modified version '$\kw{defer} \,lx\, \kw{in}\,e$' as an expression and ajusted the semantics accordingly to still be in line with the intent of Yang et al~\cite{Yang-etal:popl2012}.
\end{remark}


\begin{remark}[\kw{assert} expression]\leavevmode\label{rem:assert}
The original syntax, `$\kw{assert}\,e$', has been modified in accordance with the original translation scheme in Yang et al~\cite[Figure~6]{Yang-etal:popl2012} to 
include an `$\kw{in}~e$' part. (A fact that equally eliminates the need for the unit primitive $()$ as originally stated in Yang et al~ \cite[Figure~3]{Yang-etal:popl2012}.) These decisions render an assert expression on the form: `$\kw{assert}\, (e\, \Rightarrow(lx=b))\, \kw{in} \, e$'. 
\end{remark}

\begin{definition}[\lambdaJ lexical tokens]\leavevmode\label{def:tokens}
Lexical tokens are the same as for Jeeves \cf Definition~\ref{litlextok}. $Level$ (`$lx$') tokens are by default logical variables at the \lambdaJ\ level.
\end{definition}

\begin{haskell}[abstract {\lambdaJ} expression syntax]\leavevmode\label{hs:lamjexp}
The algebraic constructors for the $Exp$ sort are implemented as a one-to-one map to Haskell constructors for the \textsf{Exp} datatype.
The $Op$ sort is implemented by the datatype \hask|Op|, and $UOp$ is implemented by \hask|UOp|. 
The individual operations are implemented with (self-explanatory)  Haskell constructors.  %% Notice that the operator \hask|OP_PLUS|  
 %%        -- OP_PLUS overloaded: arithmetic and list concatenation          

\begin{code}
data Exp = E_BOOL Bool | E_NAT Int | E_STR String | E_CONST String  
         | E_VAR Var   | E_CONTEXT 
         | E_LAMBDA Var Exp | E_THUNK Exp 
         | E_OP Op Exp Exp  | E_UOP UOp Exp                    
         | E_IF Exp Exp Exp | E_APP Exp Exp                   
         | E_DEFER Var Exp | E_ASSERT Exp Exp                  
         | E_LET Var Exp Exp                   
         | E_RECORD [(FieldName,Exp)] 
         | E_FIELD Exp FieldName
         deriving (Ord,Eq)

data Op = OP_PLUS | OP_MINUS | OP_LESS | OP_GREATER 
        | OP_EQ | OP_AND | OP_OR | OP_IMPLY
        deriving (Ord,Eq)

data UOp = OP_NOT   deriving (Ord,Eq) 

data FieldName = FIELD_NAME String  deriving(Ord,Eq)
data Var = VAR String deriving (Ord,Eq)
\end{code}
\end{haskell}



Finally, we need to characterize the notion of a \emph{\ix{value expression}}, among which is the notion of a thunk-expression as discussed above. As illustrated by the Ackermann program example, the problem is that "problematic" expressions might get unintentionally evaluated at compile-time instead of in a run-time scope, because the language is eager. To make sure that only expressions that are "safe" to bind in Definition~\ref{lamjpgm} are in fact those allowed in the static binding environment, we introduce the notion of a value expression (`$ve$') as an expression on \ix{weak head normal form}.
To summarize, such expressions in \lambdaJ may, as expected, take one of three forms:
\begin{itemize}
\item constant expressions (literals or records of values),
\item non-constant functions (`$\lambda x \kw{.} e$'), or
\item constant functions (`$\kw{thunk}\,e$').
\end{itemize}
 To be precise, we specify an auxiliary \ix{value sort} $ValExp \subseteq Exp$ with the purpose of syntactically capturing those sets of expressions, followed by its Haskell implementation: 
\begin{definition}[value expressions]\label{valexp}
\begin{align*}
     ve \in ValExp &~ :: = ~b~|~n~|~s~|~c~|~ \lambda x \kw{.} e ~|~ \kw{thunk} \,e ~|~ \kw{record}\,fi_1:ve_1\dots fi_m:ve_m  %% fjernes:  x~|~\kw{context}~
\\ %% \\[-2\jot]
\text{where} ~&  m\geq 1
\end{align*}
\end{definition}

\begin{haskell}[value expressions]\leavevmode\label{hs:valexp}
The \ix{\lambdaJ\ value property} is straight forwardly implemented as a Haskell predicate \textsf{isValue} over the \textsf{Exp} datatype.
\begin{code}
isValue (E_BOOL _)       = True
isValue (E_NAT _)        = True
isValue (E_STR _)        = True
isValue (E_CONST _)      = True
isValue (E_LAMBDA _ _)   = True
isValue (E_THUNK _)      = True
isValue (E_RECORD xes)   = and [isValue e | (_,e)<-xes]
isValue _                = False
\end{code}
\end{haskell}




\section{The {\lambdaJ} translation}\label{lamjtrans} 

In this section, we formally present a \ix{syntax directed translation} of the concrete Jeeves syntax  to \lambdaJ\ , alongside its Haskell implementation.
The translation follows the original outline in Yang et al~\cite[Fig.~6]{Yang-etal:popl2012} on critical syntax parts, but has been extended to accomodate 
modifications as accounted for in Section~\ref{impldesign},~\ref{jeevesconcrsyntax},\,and \ref{lamjabssyntax}. 
Specifically, we have added a translation from a Jeeves program to our notion of a \lambdaJ\ program. %% in Definition~\ref{transjpgm}.



The translation is formalized as a  \emph{derivation}, marked by  $\llbracket\,  \_ \, \rrbracket$, over the program, expression, and token sorts.
A \ix{derivation} is a particular simple form of compositional translations that is characterized by the fact that syntax cannot be re-used, and 
side-conditions cannot be stated, which makes them particularly easy to reason about termination, and straightforward to implement.  %%\cite{}. <-- Schmidth??? denotation a well def meaning?


The Haskell implementation is given as a set of \emph{Jeeves parsers}, which builds abstract \lambdaJ\ syntax trees in accordance with the abstract syntax outlined in Section~\ref{lamjabssyntax}.
The parsers are implemented using the Haskell monadic parser combinator library~\cite{HuttonMeijer:jfp1998}, which is also included in Appendix~\ref{parserframework}.





\begin{definition}[translation of Jeeves program]\label{transjpgm}
\begin{align*}
  \left\llbracket
     {\begin{aligned}
       &\texttt{let}~ f_1~x_{11}\dots x_{1n_1}\,\texttt{=}\,e_1 \\[-2\jot]
       &\vdots \\[-\jot]
       &\texttt{let}~ f_m~x_{m1}\dots x_{mn_m}\,\texttt{=}\,e_m \\
       &\texttt{output}_1~ \{e_1'\}~ e_1'' \\[-2\jot]
       &\vdots \\[-\jot]
       &\texttt{output}_k~ \{e_k'\}~ e_k''
     \end{aligned}}
  \right\rrbracket
  &=
  {\begin{aligned}
       \kw{letrec}~ &f_1~\kw{=}~  e_1'''  \\[-2\jot]  %% (x_{11},\dots, x_{1n_1}) \\[-2\jot]
                    &\dots \\[-\jot]
                    &f_m~\kw{=}~ e_m'''  \\             %% (x_{m1},\dots, x_{mn_m}) \\
       \kw{in} ~    &\kw{output}_1~ (\kw{concretize}\, \llbracket e''_1 \rrbracket\, \kw{with} \, \llbracket e'_1 \rrbracket) \\[-2\jot]
                    &\dots \\[-\jot]
                    &\kw{output}_k~ (\kw{concretize}\, \llbracket e''_k \rrbracket\, \kw{with} \, \llbracket e'_k \rrbracket) 
   \end{aligned}}
\\
\intertext{where}
  e_i'''
  =
     &{\begin{cases}     
       \kw{thunk}\,\llbracket e_i \rrbracket            &\text{if}~ n_i =0 ~\land~ \llbracket\, e_i \, \rrbracket~ \notin ValExp\\
 %%      \kw{thunk}\,\llbracket x \rrbracket              &\text{if}~ n_i =0 ~\land~ \llbracket\, e_i \, \rrbracket~ = x \\
       \lambda x_{i1}. \dots \lambda x_{in_i}. \llbracket e_i \rrbracket  &\text{otherwise}\\
     \end{cases} }  
\\
   & 1 \leq i \leq m, ~ m \in \mathbb{N},~  n_i \in \mathbb{N}_{0}
\\[-2\jot]
\intertext{and}  ~ k,m \in \mathbb{N} , ~ f, x \in Var, ~ & e, e', e'',e''' \in Exp, ~ \kw{output} \in Outputkind
\end{align*}
\end{definition}
Using the introduced notation, we begin by explaining the specifics of a constant function (that is a function with no function arguments):

\begin{remark}[constant function]\label{confun}
We tacitly assume that given $m \in \mathbb{N}$ functions, originally defined by $m$ let-statements,  
and given some function `$f_i,\, 1 \leq i \leq m$', we have that `$n_i=0$', which  corresponds to `$f_i$' being a constant function. 
In particular it entails that `$e_i'''= \llbracket e_i \rrbracket$', where the expression-translation `$\llbracket e_i \rrbracket$' is assumed to be some \lambdaJ\ expression.
\end{remark}

The where-clause specifies the shape of the translated expressions, symbolized by `$ e_i'''$', as it is statically bound in the recursive (function) binding environment by the equation `$f_i= e_i'''$' (for some $i$ where  $m \in \mathbb{N},\, 1 \leq i \leq m$). A problematic scoping situation might occur during translation, when `$f_i$' defines a constant function as discussed in detail in Section~\ref{lamjabssyntax}. Because `$e_i'''$' may equal any expression form, we have to confine any impending static evaluation by wrapping all non-value expressions with a 'thunk'. It means vice versa, that constant functions which \emph{are} in fact value expressions can be safely bound:

\begin{remark}[constant function translation]\leavevmode
  If for some $m \in \mathbb{N},\, 1 \leq i \leq m$ we have $n_i =0$  (no function arguments), and  $\llbracket e_i \rrbracket \in ValExp$ (value expression), then the 
where-clause of the translation rule entails  $ e_i''' =  \llbracket e_i \rrbracket$ (function is a \ix{constant value expression}).
\end{remark} 

From Definition~\ref{valexp} follows immediately the following invariant:

\begin{lemma}[binding environment invariant]\label{veInvar}
The right hand side of the letrec-function-bindings  are all \ix{value expressions}, \ie, for some  $m \in \mathbb{N}$ we have
$$ \forall i \in \mathbb{N},\, 1 \leq i \leq m, \, n_i \in \mathbb{N}_{0}\,: e_i''' \in ValExp $$.
\end{lemma}


\begin{haskell}[translation of Jeeves program]\leavevmode\label{hs:transjpgm}
\begin{code}
programParser :: FreshVars -> Parser Program                
programParser xs = do recb <- manyParser recbindParser xs1 success
                      psts <- manyParser outputstatParser xs2 success
                      return (P_LETREC recb psts)
  where ~(xs1,xs2) = splitVars xs                                                                                         

recbindParser :: FreshVars -> Parser Binding
recbindParser xs = do token (word "let")
                      f <- token ident
                      e <- argumentAndExpThunkParser xs
                      optional (token (word ";"))
                      return (BIND (VAR f) e)

argumentAndExpThunkParser ::  FreshVars -> Parser Exp
argumentAndExpThunkParser xs = do vs <- many (token ident)   -- accumulates function parameters
                                  token (word "=")
                                  e <- expParser xs
                                  if ((null vs) && not (isValue e)) 
                                    then return (E_THUNK e)     -- constant, non-value expression
                                    else return (foldr f e vs)  -- guaranteed to be a value by the guard
  where
    f v1 e1 = E_LAMBDA (VAR v1) e1

outputstatParser :: FreshVars -> Parser Statement  
outputstatParser xs = do output <- outputToken    
                         token (word "{")
                         e1 <- expParser xs1    -- should evaluate to concrete value                     
                         token (word "}")
                         e2 <- expParser xs2   
                         optional (token (word ";"))
                         return (CONCRETIZE_WITH  output e2 e1)   
  where ~(xs1,xs2) = splitVars xs                                                                
\end{code}
\end{haskell}                          

The expression translation follows the concrete expression syntax structure in  Definition~\ref{def:jeeves-concr-syn}, from 
which we have tacitly adopted all algebraic  specifications.


\begin{definition}[translation of Jeeves expressions]\label{transjexp}
\begin{align*}
\llbracket~e_1 \texttt{;}~ \dots ~e_n \texttt{;}~e~\rrbracket
& = \kw{let}~ x_1 = \llbracket e_1\rrbracket ~\texttt{in} ~ \dots ~\kw{let}~ x_n = \llbracket e_n \rrbracket ~\texttt{in} ~\llbracket e \rrbracket  
\\
& \qquad \text{where $x_1 \dots x_n$ \ix{fresh}, $0 \leq n$}
\\
\llbracket~ \texttt{if}~e_1~\texttt{then}~e_2~\texttt{else}~e_3 ~\rrbracket
&= \kw{if}~\llbracket e_1\rrbracket~\kw{then}~\llbracket e_2\rrbracket~\kw{else}~\llbracket e_3\rrbracket
\\
\llbracket~ \texttt{let}~ x ~ x_1\dots x_n \,\texttt{=}\, e_1 ~\texttt{in}~ e_2 ~\rrbracket
&= \kw{let}~ x = \lambda\,x_1\,\dots \lambda\,x_n \,\kw{.}\, \llbracket e_1\rrbracket ~\texttt{in}~  \llbracket e_2\rrbracket 
\\
&\qquad \text{where $0 \leq n$}
\\
\llbracket~ \texttt{level} ~lx_1\,\texttt{,}\dots\texttt{,}~lx_n ~\texttt{in} ~ e ~\rrbracket
&= \kw{defer}~lx_1 ~ \kw{in} ~\dots~ \kw{in} ~ \kw{defer}~ lx_n~\kw{in} ~\llbracket e\rrbracket 
\\
&\qquad \text{where $1 \leq n$}
\\
\llbracket~ \texttt{policy}~lx \, \texttt{:} \, e_1 ~ \texttt{then} ~ lv ~\texttt{in}~ e_2 ~\rrbracket
&= \kw{assert}~(\llbracket e_1\rrbracket \Rightarrow (lx=\llbracket lv\rrbracket)) ~\kw{in}~ \llbracket e_2\rrbracket
\\
\llbracket~ e ~op~ e ~\rrbracket
&= \llbracket e\rrbracket ~op~ \llbracket e \rrbracket
\\
\llbracket~ f\!e ~ pe ~\rrbracket
&= \llbracket f\!e\rrbracket ~ \llbracket pe\rrbracket
\\
\llbracket~ \texttt{context} ~\rrbracket
&= \kw{context}
\\
\llbracket~ \texttt{<}ae_1\texttt{|}ae_2\texttt{>}\,\texttt{(}lx\texttt{)} ~\rrbracket
&= \kw{if}~lx~\kw{then}~\llbracket ae_2\rrbracket~\kw{else}~\llbracket ae_1\rrbracket
\\
\llbracket~ \texttt{\{}\,x_1 \texttt{=} e_1 \texttt{;}\dots\texttt{;} x_n \texttt{=} e_n ~\texttt{\}} ~\rrbracket
&= \kw{record}~x_1\texttt{=}\llbracket e_1\rrbracket\,\dots\,x_n\texttt{=}\llbracket e_n\rrbracket 
\\
& \qquad \text{where $0 \leq n$}
\\
\llbracket~ pe\,\texttt{.}\,x ~\rrbracket
&= \llbracket~ pe\rrbracket\,\texttt{.}\,x
\\
\llbracket~ \texttt{!}\,pe ~\rrbracket
&= {!\,\llbracket~ pe\rrbracket}
\\
\llbracket~ \texttt{(} e \texttt{)} ~\rrbracket
&= \llbracket e \rrbracket
\\
\llbracket~ lit ~\rrbracket
&= lit
\end{align*}
\end{definition}

\begin{remark}[simple expression sequence translation]\label{simeseq}\leavevmode
An expression sequence `$e$' with only one expression is described by index `$n=0$.
\end{remark}

\begin{remark}[simple let expression translation]\label{simlet}\leavevmode
A let expession `$\texttt{let}~ x \,\texttt{=}\, e_1 ~\texttt{in}~ e_2$' with only one variable binding is described by index  `$n=0$'.
\end{remark}


\begin{remark}[empty record translation]\label{emptyrec}\leavevmode
We represent an empty record by the index `$n=0$', and its translation by the keyword \kw{record}.   
\end{remark}

The  expression translation is implemented as a \emph{Jeeves expression parser} that builds abstract \lambdaJ expression syntax trees, \cf, Definition~\ref{lamjexp}. Recall that all parsers are implemented using the Haskell monadic parser combinator library~\cite{HuttonMeijer:jfp1998}, which is explicitly included in Appendix~\ref{parserframework}.

\begin{haskell}[translation of Jeeves expressions]\leavevmode\label{hs:transjexp}

\begin{code}
expParser :: FreshVars -> Parser Exp
expParser xs = do es <- manyParser1 semiUnitParser xs1 (token (word ";"))
                  return (snd (foldr1 f (zip xs2 es)))
  where
    f (x1,e1) (x2,e2) = (x1, E_LET x1 e1 e2)
    (xs1,xs2) = splitVars xs
    semiUnitParser xs = ifParser xs +++ letParser xs  +++ levelParser xs +++ policyParser xs +++ logicalImplyParser xs 

ifParser xs = do token (word "if") 
                 e1 <- expParser xs1
                 token (word "then") 
                 e2 <- expParser xs2
                 token (word "else") 
                 e3 <- expParser xs3
                 return (E_IF e1 e2 e3)
  where  ~(xs1,xs2,xs3) = splitVars3 xs 

letParser xs = do token (word "let")
                  x <- token ident
                  xse1 <- argumentAndExpParser xs1
                  token (word "in")
                  e2 <- expParser xs2
                  return (E_LET (VAR x) xse1 e2)
  where  ~(xs1,xs2) = splitVars xs

argumentAndExpParser xs = do vs <- many (token ident)
                             token (word "=")
                             e <- expParser xs
                             return (foldr f e vs)
  where
    f v1 e1 = E_LAMBDA (VAR v1) e1

levelParser xs = do token (word "level")
                    lx <- levelIdent     
                    lxs <- many commaTokenLevelIdent
                    token (word "in")
                    e <- expParser xs1
                    return (foldr f e (lx:lxs))
  where
    commaTokenLevelIdent = do token (word ",")
                              lx <- levelIdent 
                              return lx
    f lx e = E_DEFER lx e
    ~(xs1,lys) = splitVars xs

policyParser xs = do token (word "policy")  
                     lx <- levelIdent
                     token (word ":")
                     e1 <- expParser xs1
                     token (word "then")
                     lv <- levelToken
                     token (word "in")
                     e2 <- expParser xs2
                     return (E_ASSERT (E_OP OP_IMPLY e1 (E_OP OP_EQ (E_VAR lx) lv)) e2)
  where
    ~(xs1,xs2) = splitVars xs

logicalImplyParser xs = do loe <- logicalOrParser xs1
                           loes <- optional (logicalImplyTailParser xs2)
                           return (foldl f loe loes)
  where
    f loe1 loe2 = E_OP OP_IMPLY loe1 loe2
    ~(xs1,xs2) = splitVars xs

logicalImplyTailParser xs = do token (word "=>")
                               loe <- logicalOrParser xs
                               return loe

logicalOrParser xs = do lae <- logicalAndParser xs1
                        laes <- many (logicalOrTailParser xs2)
                        return (foldl f lae laes)
  where
    f lae1 lae2 = E_OP OP_OR lae1 lae2
    ~(xs1,xs2) = splitVars xs

logicalOrTailParser xs = do token (word "||")
                            lae <- logicalAndParser xs
                            return lae

logicalAndParser xs = do ce <- compareParser xs1
                         ces <- many (logicalAndTailParser xs2)
                         return (foldl f ce ces)
  where
    f ce1 ce2 = E_OP OP_AND ce1 ce2
    ~(xs1,xs2) = splitVars xs

logicalAndTailParser xs = do token (word "&&")
                             ce <- compareParser xs
                             return ce

compareParser xs = do ae <- additiveParser xs1
                      copae <- optional (compareTailParser xs2)
                      if (null copae) then return ae 
                        else return (E_OP (fst (head copae)) ae (snd (head copae)))
  where ~(xs1,xs2) = splitVars xs

compareTailParser :: FreshVars -> Parser (Op,Exp)
compareTailParser xs = do cop <- compareOperator 
                          ae <- additiveParser xs
                          return (cop,ae)

compareOperator = wordToken "=" OP_EQ +++ wordToken "<" OP_LESS +++ wordToken ">" OP_GREATER

additiveParser xs =  (do fe <- functionParser xs1
                         aopae <- optional (additiveTailParser xs2)
                         if (null aopae) then return fe else return ((head aopae) fe))
                     +++
                     (do aopae <- additiveTailParser xs
                         return (aopae (E_NAT 0)))
  where ~(xs1,xs2) = splitVars xs  

additiveTailParser :: FreshVars -> Parser (Exp -> Exp)       
additiveTailParser xs =  do aop <- additiveOperator 
                            fe <- functionParser xs1  
                            aopae <- optional (additiveTailParser xs2)
                            if (null aopae) then return (\x -> E_OP aop x fe)
                              else return (\x -> (head aopae) (E_OP aop x fe))
  where ~(xs1,xs2) = splitVars xs    

additiveOperator = wordToken "+" OP_PLUS +++ wordToken "-" OP_MINUS

functionParser xs = do pe <- primaryParser xs1    
                       pes <- many (primaryParser xs2)
                       return (foldl E_APP pe pes)
  where ~(xs1,xs2) = splitVars xs
        
        
primaryParser xs = do pe <- primaryTailParser xs    
                      fis <- fLookup
                      return (foldl E_FIELD pe fis)  
                      
fLookup :: Parser [FieldName]
fLookup = many (do word "."
                   fi <- ident
                   return (FIELD_NAME fi))

primaryTailParser xs = literalParser xs +++ regularIdent +++
                       wordToken "context" E_CONTEXT +++
                       sensiValParser xs +++ recordParser xs +++
                       unaryParser xs +++ groupingParser xs
               
sensiValParser xs = do token (word "<") 
                       e1 <- additiveParser xs1                 
                       token (word "|")
                       e2 <- additiveParser xs2
                       token (word ">")  
                       token (word "(")  
                       lx <- levelIdent
                       token (word ")")  
                       return (E_IF (E_VAR lx) e2 e1)
  where ~(xs1,xs2) = splitVars xs                                              

recordParser xs = do token (word "{" ) 
                     fies <- manyParser fieldParser xs (token (word ";"))                
                     token (word "}" ) 
                     return (E_RECORD fies)  
                  
fieldParser :: FreshVars -> Parser (FieldName,Exp)                                                        
fieldParser xs =  do fi <- token ident
                     token (word "=")
                     pe <- primaryParser xs
                     return (FIELD_NAME fi,pe)
                    
unaryParser xs = do token (word "!")
                    pe <- primaryParser xs
                    return (E_UOP OP_NOT pe)
                                     
groupingParser xs = do token (word "(")
                       e <- expParser xs
                       token (word ")")
                       return e 
\end{code}
\end{haskell}
                                                    
 
\begin{definition}[\ix{translation of Jeeves lexical tokens}]\label{litlextok3}\leavevmode
The Jeeves lexical tokens, specified in Definition~\ref{litlextok}, formally carries over to \lambdaJ\ as the identical token sets,
 except for $Level$ tokens, which maps to $Boolean$ in the following way:
 $$  \llbracket \texttt{top} \rrbracket = \kw{true}  \qquad    \llbracket \texttt{bottom} \rrbracket = \kw{false}  $$
\end{definition}

\begin{haskell}[translation of Jeeves lexical tokens]\leavevmode\label{hs:transjtokens}

The identity mapping of the Jeeves token set (except for level-tokens) to  \lambdaJ\ token set, is implemented by letting the parser "build" the equivalent
 implementation of those tokens (Haskell~\ref{hs:litlextok})  directly  as represented in \lambdaJ (Haskell~\ref{hs:lamjexp}). 
$Level$ tokens, however, are represented as boolean expressions \cf Definition~\ref{litlextok3}. 

For reasons of efficiency, we do distinguish  between the representation of  "regular" variables (`$x$') and "level" variables (`$lx$') in our 
implementation, except when translating  sensitive values.
 
Notice the definition of a "helper", the \hask|literalParser|, which parses Jeeves literals directly.
\begin{code}
literalParser xs = booleanToken  +++  naturalToken +++ stringToken +++ constantToken

booleanToken = wordToken "true" (E_BOOL True)
               +++ wordToken "false" (E_BOOL False)

naturalToken = do n <- token nat  
                  return (E_NAT n)

stringToken = do cs <- token string
                 return (E_STR cs)
                 
constantToken = do cs <- token constant
                   return (E_CONST cs)
                          
regularIdent :: Parser Exp 
regularIdent = do x <- token ident            
                  return (E_VAR (VAR x))

levelIdent :: Parser Var              
levelIdent =  do lx <- token ident
                 return (VAR lx)           
                 
levelToken :: Parser Exp 
levelToken =  wordToken "top" (E_BOOL True) +++ wordToken "bottom" (E_BOOL False) 
                 
outputToken = token (word "print")  +++ token (word "sendmail")                 
\end{code}
\end{haskell}



We exploit that Haskell is a lazy language that permits cyclic data definitions 
to maintain an infinite supply of \ix{fresh variable names} (a need reflected by Definition~\ref{transjexp} and Definition~\ref{evaldefer}).

\begin{haskell}[fresh variables]\leavevmode\label{hs:freshvars}
We implement an infinite supply of distinct variables (and infinite, disjoined, derived sublists) by the variable generator \hask|iterate|.
 (The definition of \hask|iterate| is in fact cyclic/infinite in its definition.) 

\begin{code}
type FreshVars = [Var]

vars :: FreshVars
vars = map (\n->VAR ("x"++show n)) (iterate (\n->n+1) 1)

splitVars :: FreshVars -> (FreshVars,FreshVars)
splitVars xs = (odds xs, evens xs) where
  odds  ~(x:xs) = x : evens xs
  evens ~(x:xs) = odds xs

splitVars3 :: FreshVars -> (FreshVars,FreshVars,FreshVars)
splitVars3 vs = (xs, ys, zs) where
   (xs,yzs) = splitVars vs
   (ys,zs) = splitVars yzs
\end{code}
\end{haskell}


Finally, we present a formal translation of the first of our canonical examples: the Jeeves naming policy program from Example~\ref{confmanage} and ~\ref{ntp}.

\begin{example}[Name policy program translation]\leavevmode\label{ntp2}
\begin{align*}
  \left\llbracket
     {\begin{aligned}
       &\texttt{let} ~ name \, \texttt{=}\,  \texttt{level} ~ a ~in ~ \texttt{policy}\, a \, \texttt{:}\, !(\texttt{context} = alice)~ \texttt{then}~ bottom ~\texttt{in} ~\texttt{<}"Anonymous"\texttt{|}"Alice"\texttt{>}\texttt{(}a\texttt{)}\, \rrbracket \\
       &\texttt{let} ~ msg \,\texttt{=}\, "Author ~ is ~"  + \,  name   \\                    
       & \texttt{print}~ \texttt{{}alice\texttt{}}~ msg \\
       & \texttt{print}~ \texttt{{}bob\texttt{}}~ msg
     \end{aligned}}
  \right\rrbracket
   = ~\\ \\ 
{\begin{aligned}
       \kw{letrec}\,&\,name \kw{=} \kw{thunk} ( \kw{defer}\, a\, \kw{in}\, (\kw{assert}\, ( !(\kw{context} = alice) => (a=false))\, in\,  \llbracket \texttt{<}"Anonymous" \texttt{|} "Alice" \texttt{>} (a)\rrbracket )) \\
                    &\,msg \kw{=}  \kw{thunk}\,("Author~ is~ " + \,name) \\    
       \kw{in} \,    &\,\kw{print}\, (\kw{concretize}\,  msg \, \kw{with} \, alice) \\
                    &\,\kw{print}\, (\kw{concretize}\,  msg \, \kw{with} \, bob) 
   \end{aligned}}
\\
{\begin{aligned}
\intertext{where} & \llbracket \texttt{<}"Anonymous" \texttt{|} "Alice" \texttt{>}(a)\rrbracket &  = \kw{if}~a~\kw{then}~"Alice"~\kw{else}~"Anonymous"
   \end{aligned}}
\end{align*}
\end{example}



\section{Scoping and symbolic normal forms}\label{lamjval}


In this section we specify the notions of scope and symbolic normal forms of \lambdaJ for use in later sections. 
According to Yang et al~\cite[Figure~3]{Yang-etal:popl2012}, dynamic expression evaluation generally speaking  happens in 3 consecutive steps:
\begin{enumerate}
\item reduction all the way to temporary \emph{normal form} that may still contain dynamic, unresolved symbolic sub-expressions and constraints, followed by
\item \emph{\ix{constraint resolution}}, which resolves the consequences of knowing the value of the input variable "\kw{context}", to find a solution to the program constraint set, and finally, 
 %%%  current constraint set --- per expression or program? 
\item completing the reduction of the temporary normal forms, instantiated with the constraint solution.
\end{enumerate}

The semantic set of temporary normal forms, which are denoted \ix{symbolic normal forms} in accordance with Yang et al~\cite[Figure~2]{Yang-etal:popl2012},  is specified by the algebraic $Value$ sort in Definition~\ref{semval}. Depending on whether they contain unresolved residues, they are either categorized as  \ix{\emph{symbolic values}} or \ix{\emph{concrete values}}.  
In order to semantically reflect \ix{lexical scoping} during expression reduction, we have added the notion of a \emph{\ix{closure}} compared to~\cite[Fig.~2]{Yang-etal:popl2012}). 
Generally speaking, a closure consists of a \emph{function expression}, constant or non-constant, together with an \emph{environment} component $\rho$, 
which holds the set of (static) variable bindings of that expression. In \lambdaJ, such closures take the form:  $(\kw{thunk}\,e,\rho)$, $(\lambda x{.}e,\rho)$. We define closures as  concrete (symbolic) normal forms, \ie, as concrete values of the $Value$ sort. %% WHY??? 


In the remainer of this section we formally present the symbolic normal forms  followed by 
a specification of the static \lambdaJ binding environment, all in tandem with their Haskell implementations.
The former specification is presented as an algebraic specification in Definition~\ref{semval}, the latter as as a partial domain function in Definition~\ref{def:environments}.
\begin{definition}[\ix{symbolic normal forms}]\label{semval}       
\begin{align*}
  \upsilon \in Value ::& = \kappa ~|~ \sigma
\\
  \kappa \in \ix{ConcreteValue} :: & = b~|~ n ~|~ s ~|~ c ~|~  \kw{error}  \\      
                              & ~|~ (\lambda x{.}e,\rho) ~|~ (\kw{thunk}\,e,\rho)  \\
                              & ~|~ \kw{record}~x{:}\kappa \,\cdots\, x{:}\kappa
\\
  \sigma \in \ix{SymbolicValue} :: & = x ~|~ lx ~ | ~ \kw{context} ~|~ \sigma\,\kw{.}\,x \\
                              & ~|~ \sigma ~op~ \upsilon ~|~ \upsilon ~op~ \sigma ~|~ uop~\sigma \\
                              & ~|~ \kw{if}\,\sigma\,\kw{then}\,\upsilon\,\kw{else}\,\upsilon \\
                              & ~|~ \kw{record}~x{:}\sigma   ~ x{:}\upsilon \,\cdots\, x{:}\upsilon \\
                              & ~|~ \kw{record}~x{:}\upsilon ~ x{:}\sigma   \,\cdots\, x{:}\upsilon \\
                              & \vdots\\
                              & ~|~ \kw{record}~x{:}\upsilon ~ x{:}\upsilon \,\cdots\, x{:}\sigma
\\[-2\jot]
\\
\text{where}~ b \in Boolean, \, & n \in Natural,  \,  s \in String, \,  c \in Constant, \\
      \text{and} ~ & x \in Identifier, \rho \in Environment.
\end{align*}
\end{definition}

\begin{remark}[\kw{error} normal form]\leavevmode
Following Yang et al~\cite[Fig.~2]{Yang-etal:popl2012}, we have added \kw{error} as a concrete normal form to reflect a 
 semantically erroneous evaluation state.
\end{remark}

\begin{remark}[\kw{record} normal forms]\leavevmode
  We have added two distinct normal forms of the record data structures. A record where all fields are on  
concrete normal form ($\kappa$) is itself on concrete normal form ($\kappa$). A record where "at least" one field 
is on symbolic normal form ($\sigma$) is on symbolic normal form ($\sigma$).
\end{remark}


\begin{haskell}[symbolic normal forms]\leavevmode\label{hs:semval}
The algebraic $Value$ constructors for the $Value$ sort are implemented as Haskell constructors for the \textsf{Value} datatype.
The distinction between concrete and symbolic is implemented by the predicates \textsf{isConcrete} and \textsf{isSymbolic} over $Value$.
\begin{code}
data Value = -- Concrete values
             V_BOOL Bool | V_NAT Int | V_STR String | V_CONST String | V_ERROR 
           | V_LAMBDA Var Exp Environment | V_THUNK Exp Environment
           | V_RECORD [(FieldName,Value)]  
             -- Symbolic values
           | V_VAR Var | V_CONTEXT 
           | V_OP Op Value Value | V_UOP UOp Value 
           | V_IF Value Value Value | V_FIELD Value FieldName
           deriving (Ord,Eq)

isConcrete (V_BOOL _)        = True
isConcrete (V_NAT _)         = True
isConcrete (V_STR _)         = True
isConcrete (V_CONST _)       = True
isConcrete (V_ERROR)         = True
isConcrete (V_LAMBDA _ _ _)  = True
isConcrete (V_THUNK _ _)     = True
isConcrete (V_RECORD xvs)    = all (\b->b) [isConcrete v | (_,v) <- xvs]
isConcrete _                 = False

isSymbolic v = not (isConcrete v) 
\end{code}
\end{haskell}



\begin{definition}[static binding environment]\leavevmode\label{def:environments}
The concept of a static binding environment $\rho$ is formalized in terms of new semantic meta-notation on \lambdaJ\ variables and values:   
\begin{itemize}
\item $\rho$ denotes an \emph{environment} that maps variables to (constant or symbolic) values,
\item $\rho[x \mapsto \upsilon]$ denotes an environment obtained by extending the environment $\rho$ with the  map $x$ to $\upsilon$, and
\item $\rho(x)$ denotes the value obtained by looking up x in the environment.
\end{itemize}

Environment $\rho$ is recursively defined as a \emph{partial domain function} \cf Schmidt\,\cite{Schmidt:1986}:  
\begin{align*}
  \rho : \text{variables} &\to Value_{\bot} \\[1ex]
  \text{For all $y$ $\in$ DOM$(\rho[x \mapsto \upsilon])$}: \\[1em]
  \rho[x \mapsto \upsilon](y) &=_{\text{def}} 
    {\begin{cases}
      \upsilon &\text{if $y=x$}\\
      \rho(y)  &\text{if $y\neq x$}
     \end{cases}}\\
  \epsilon(y) &=_{\text{def}} \lambda y {.} \bot
\end{align*}
where $\epsilon$ denotes the empty environment, and the co-domain $Value_{\bot}$ is the (lifted) domain of semantic values. 
\end{definition}


\begin{haskell}[static binding environment]\label{hs:statenv}
We use standard Haskell maps to implement the static binding environment in a straight forward manner.

\begin{code}
type Environment = Map Var Value
\end{code}

\begin{itemize}
\item $\rho(x)$ is implemented by \hask|rho!x|
\item $\rho[x \mapsto v]$ is implemented by \hask|insert x v rho|
\item $\epsilon$, aka $\lambda y {.} \bot$, is implemented by \hask|empty|
\end{itemize}
\end{haskell}








\section{The \ix{constraint environment}}\label{ref:constraints}

In this section, we describe the constraint environment which is created at the \lambdaJ-level during program execution, in accordance with Yang et al~\cite[Fig.~3]{Yang-etal:popl2012}. The ensemble of constraints has been defined as an additional component to the (static) binding environment of the dynamic \lambdaJ semantics. As mentioned in the three step description of Section~\ref{lamjval}, the first part of a \lambdaJ-evaluation causes constraints to be accumulated as the privacy enforcing expressions get evaluated, followed by a constraint resolution step, conditioned by the known value of the input. The actual constraint resolution is side stepped in the original semantics by Yang et al~\cite[Fig.~3]{Yang-etal:popl2012}, and simply reduced to the question of whether there exists a solution which solves the constraint set or not. Constraint programming systems in fact combines a constraint solver and a search engine in a very (monadic) flexible way as described by others~\cite{Schrijvers:2009:MCP:1735546.1735549}. In this report, however, we simply analyse the monadic structure of the constraint set semantics.

A \emph{\ix{constraint environment}} is divided into two base sets of constraints: the \emph{\ix{current set of constraints}} 
 denoted by the algebraic  $\Sigma$ sort (\ix{hard constraints}), and the \emph{\ix{constraints on default values}} for logical variables, denoted 
 by the algebraic $\Delta$ sort (\ix{soft constraints}), following standard constraint programming conventions ~\cite{pgmwconstr98,RossiVB06}.

The specification of the hard constraints, $\Sigma$, is a result of constraints build up in connection with a defer and assert expression evaluation, \cf Yang et al~\cite[Fig.~3,(\textsc{e-defer}),(\textsc{e-assert})]{Yang-etal:popl2012} as "\emph{the set of constraints that must hold for all derived outputs}".
An assert expression is specified by  `$ \kw{assert}~e_1~\kw{in}~e_2 $', where `$e_1$' is a logical expression by which privacy policies get introduced \cf  
Yang et al~\cite[Fig.~6,(\textsc{t-policy})]{Yang-etal:popl2012} as hard constraints. The extension of $\Sigma$ with privacy policies `$e_1$' is reflected by the (\textsc{e-assetconstraint}) and (\textsc{e-assert}) rule. The extensions have the form `$\mathcal{G} \Rightarrow \upsilon_{e_1}$', where `$\upsilon_{e_1}$' is the result value from evaluating `$e_1$', and `$\mathcal{G}$' called the path condition is explained below.
With the modifications and assumptions in Remark~\ref{rem:defer}, a defer expression is specified by `$ \kw{defer}~lx~\kw{in}~e $',  where `$\{\upsilon\}$' in the original syntax is left unspecified by the translation ~\cite[Fig.~6,(\textsc{tr-level}),Fig.~3,(\textsc{e-defer})]{Yang-etal:popl2012}. In this syntax form, a defer expression merely has become a reflection of the introduction of level variables  \cf ~\cite[Fig.~3,(\textsc{e-defer})]{Yang-etal:popl2012}.
The extension of $\Sigma$ thus becomes reflected by the logic expression `$\mathcal{G} \Rightarrow [x \mapsto x']$'. The ($\alpha$) \emph{renaming} `$[x \mapsto x']$' of `$x$' with a fresh (logical) variable `$x'$', follows from the fact that \emph{the constraint sets have no notion of scope}. Thus, all logical variable names must be declared as globally unique.


The specifications of the soft constraints, $\Delta$, is another result of constraint build up in connection with a defer expression evaluation, as described by Yang et al~\cite[Fig.~3,(\textsc{e--defer})]{Yang-etal:popl2012} as "\emph{the constraints only used if consistent with the resulting logical environment}". This build up, however, is concerned with any logical constraints imposed directly on the variables in terms of default values, etc. As explained in Remark~\ref{rem:defer}, we tacitly assume the logical `$x'$' variable to take the default value `$\kw{true}$' during translation according to Yang et al~\cite[Fig.~6]{Yang-etal:popl2012}, something which is directly reflected in Definition~\ref{evaldefer}, as well as in the $\Delta$ specification in Definition~\ref{constrs}. Since hard and soft constraints are extended in tandem \cf Yang et al~\cite[Fig.~3,(\textsc{e-defer})]{Yang-etal:popl2012}, we tacitly assume the default constraint is only imposed on a globally unique (fresh) variable name which we denote `$x'$'. Because we have introduced an additional lexical scoping mechanism (`$\rho$') in our formalizations, we will handle renaming directly at the scoping level \cf Definition~\ref{evaldefer}, \ie,  with `$\rho[ x \mapsto x']$' alone. This simplifies the specification of hard constraints and soft constraints as described by Definition~\ref{constrs}. 

A \emph{\ix{path condition}} consists of a conjunction of symbolic values and negated symbolic values, which is used to  describe the trail (or path) of symbolic (unresolved) assumptions conditioning some expression evaluation. The only place during expression evaluation where the path condition is extended, \cf Definition~\ref{evalcond}, is when a conditional expression in the style  
               $$\text{`}\kw{if}~\sigma_1 ~\kw{then}~e_2~\kw{else}~(\kw{if}~\sigma_1' ~\kw{then}~e_2'~\kw{else}~e_3')\text{'} $$ 
is evaluated. In this case, the conditions are symbolic values, which will depend on the constraint resolution later to be resolved. There are thus two possible ways a symbolic evaluation of this if-expression can take place. If `$\sigma_1$' is assumed to become true (the `$e_2$' is evaluated), or if `$\lnot \sigma_1$' is assumed to become true (the `$ \kw{if}~\sigma_1' ~\kw{then}~e_2'~\kw{else}~e_3'$' is evaluated). The path condition simply keeps track of which assumptions have been made by making a conjunction of all such presumed conditions prior to an evaluation. In our example, we thus have that the path condition `$\lnot \sigma_1 \wedge \sigma_1'$' holds prior to `$e_2'$' evaluation.   
In Definition~\ref{constrs}, we specify a path condition this way and denote it $\mathcal{G}$. It is defined as an element of the algebraic $PathCondition$ sort, together with the algebraic notation for the constraint environment, $\Sigma$ (hard constraints), and $\Delta$ (soft constraints). 








 

\begin{definition}[\ix{hard constraints, soft constraints, and path condition}]\label{constrs}\leavevmode
\begin{align*}
       \Sigma  & = \mathcal{P}(\mathcal{G} \Rightarrow \upsilon) \\ % Instead of \mathcal{P}(\mathcal{G} \Rightarrow \upsilon[x \mapsto x'])
       \Delta  & = \mathcal{P}(\mathcal{G} \Rightarrow x = \upsilon) \\ % Instead of \mathcal{P}(\mathcal{G} \Rightarrow x = \upsilon)
      \mathcal{G} \in PathCondition :: & = \sigma ~|~ \lnot \sigma ~|~ \mathcal{G} \wedge \mathcal{G} 
\\[-2\jot]
\\
\text{where}~ x \in Identifier, & ~\upsilon \in Value, \, \sigma \in SymbolicValue.
\end{align*}
  $\mathcal{P}$\ denotes the powerset in accordance with usual mathematical convention.
\end{definition}




\begin{remark}[default theory property]\label{defautheory}\leavevmode
The pair $(\Delta,\Sigma)$ logically defines a (super-normal) 
default theory, where $\Delta$ is a set of default rules (soft constraints), and $\Sigma$ is a set of first-order formulas 
(hard constraints)~\cite{Antoniou:1999:TDL:344588.344602},\,\cite{conf/dalt/Sakama08}. 
\end{remark}

The Haskell implementation of $\Sigma$ and $\Delta$ are given straightforwardly as relational lists. The relations are established as lists of pairs and lists of triplets, respectively. A relation `$\mathcal{G}\Rightarrow\upsilon$' is thus implemented by the data type \hask|(PathCondition,Value)|, and `$\mathcal{G}\Rightarrow \,x=\upsilon$' is implemented by the data type  \hask|(PathCondition,Var,Value)|. The Haskell implementation of a path condition is also given as a list. This is a list of Haskell representations of formulas or negated formulas which are presumed to hold during some specific expression evaluation.


\begin{haskell}[hard constraints, soft constraints, and path condition]\label{hs:constrs}\leavevmode
\begin{code}

data Sigma = SIGMA [(PathCondition,Value)]
emptySigma = SIGMA []
unitSigma g v = SIGMA [(g,v)]
unionSigma (SIGMA map1) (SIGMA map2) = SIGMA (map1++map2)

data Delta = DELTA [(PathCondition,Var,Value)]
emptyDelta = DELTA []
unitDelta g (x,v) = DELTA [(g,x,v)]
unionDelta (DELTA map1) (DELTA map2) = DELTA (map1++map2)

data PathCondition = P_COND [Formula] deriving (Ord,Eq)
emptyPath = P_COND []  

data Formula = F_IS Value
             | F_NOT Value
             deriving (Ord,Eq)

formulaConjunction f (P_COND fs) = P_COND (f:fs)
\end{code}
\end{haskell}



We design the Haskell implementation of the constraint sets to explicitly restrict modifications to \emph{extensions} with new
constraints, because the evaluation rules (in the following section) only extend.  To this end, we implement the constraint
environment in Haskell by \hask|Constraints a|, a \emph{\ix{monad}} over \hask|Sigma| and \hask|Delta|.  We recall that a monad in
Haskell is represented by a type class with two operators, return and bind (\hask| >>=|)~\cite{Wadler:2003:MEM:601775.601776}.  We
implement two instances on the monad, \hask{unitSigmaConstraints} and \hask{unitDeltaConstraints}. The goal of these instances is to
update /reset \hask|Sigma| and \hask|Delta| respectively.



\begin{haskell}[constraint environment]\label{hs:constrenv}\leavevmode

\begin{code}
-- Monadic notation...
data Constraints a = CONSTRAINTS Sigma Delta a
instance Monad Constraints where
  return v = CONSTRAINTS emptySigma emptyDelta v   -- the trivial monad, returning value v
  (CONSTRAINTS sigma1 delta1 v1) >>= f =           -- the sequencing of two instances
    CONSTRAINTS (unionSigma sigma1 sigma2) (unionDelta delta1 delta2) v2
      where (CONSTRAINTS sigma2 delta2 v2) = f v1

unitSigmaConstraints :: PathCondition -> Value -> Constraints Value
unitSigmaConstraints g v = CONSTRAINTS (unitSigma g v) emptyDelta V_ERROR

unitDeltaConstraints :: PathCondition -> Var -> Value -> Constraints Value
unitDeltaConstraints g x v = CONSTRAINTS emptySigma (unitDelta g (x,v)) V_ERROR
\end{code}
\end{haskell}

\begin{remark}[constraint environment updates]\leavevmode
From the evaluation semantics in Yang et al~\cite[Fig.~3,(\textsc{e-defer}),(\textsc{e-assert})]{Yang-etal:popl2012} we observe that the only semantic (expression) rules 
that potentially will affect the constraint monad directly are those concerning the \emph{privacy policy rules}, \ie, \kw{assert} (when policy constraints 
are being semantically enforced), and \kw{defer} (when confidentiality levels are being semantically differentiated/deferred) at the \lambdaJ-level.
\end{remark}





\section{The \lambdaJ evaluation semantics}\label{jeval}

In this section we specify the dynamic \lambdaJ semantics, which implements Jeeves as an \ix{eager} constraint functional language.
The specification of the evaluation engine follows the original idea by Yang et al~\cite[Fig.~3]{Yang-etal:popl2012}, but differs on a number of issues. 
Most significantly, we have reformulated  the semantics as a \emph{compositional}, \emph{ \ix{environment-based}}, \emph{\ix{big step semantics}}, as opposed to 
the original  \emph{non-compositional}, \emph{\ix{substitution-based}}, \emph{\ix{small-step semantic}} formulation~\cite[Fig.~3]{Yang-etal:popl2012}. 
Primarily, in order to enhance the ability to proof semantical statements, because proofs then can be carried inductively over the height of the proof trees (something which breaks down in general when substitution into subterms is allowed like in the original \lambdaJ semantics). 
As something new, we have added a formal notion of a Jeeves, aka a \ix{\lambdaJ program evaluation}. Finally, we have added the notion of
 \ix{lexical variable scoping}  to manage static bindings.\footnote{\emph{Lexical} or \emph{static scoping} means that declared variables only occur  within the text of the declared program structure.} This has been done by enhancing the semantics with a (new) \ix{binding environment} feature ($\rho$  and closures) as discussed in Section~\ref{lamjval}. The Haskell implementation is presented alongside  each individual evaluation rule. 












 We begin by formalizing three peripheral semantic \lambdaJ concepts needed to proceed with the actual evaluation semantics presentation. The \emph{\ix{input-output domain}}, the final set of \emph{solution constrains} to be resolved, and the \emph{runtime (side) \ix{effects}} from running a \lambdaJ program. We then proceed by a re-formalization of the dynamic semantics as a big step, compositional, non-substitutional semantics as discussed above, alongside the associated Haskell implementation.


The first thing to formally consider is the \ix{input}-\ix{output} functionality of Jeeves. According to Yang et al~\cite[Fig.~3]{Yang-etal:popl2012} the input and output at the Jeeves source level is specified by  $$\texttt{print}\,\{\,\emph{some-input}\,\}\, \emph{some-output}$$ statements, where the input is specified between the syntactical braces (\{\}), and the output is specified right after the braces.
Thus, no input enters a Jeeves aka \lambdaJ program at runtime but is given a priori, as a static part of the program structure. 
A program outcome amounts semantically to "the effect" of running a set of Jeeves print statements. (In our setting, `\texttt{print}' is in fact generalized to `\texttt{outputkind}', thus accounts for several different channels like `\texttt{print}', `\texttt{sendmail}', etc.)  According to Yang et al~\cite[Fig.~3, Fig.~6]{Yang-etal:popl2012}, the print statement translates to 
$$\kw{print}\,(\,\kw{concretize}\,e_v \, \kw{with} \, \upsilon_c\,)$$ where `$\upsilon_c$' is the translation of the \emph{some-input} value, and `$e_v$' is the translation of the \emph{some-output} expression. Input values are semantically concrete values `$\upsilon_c$' (as hinted by the subscript `$c$'), that is either a \emph{literal} or a \emph{record}. Output values are semantically defined by the outcome of the `$e_v$' evaluation, which we here assume results in either a \emph{literal}, a \emph{record}, or \emph{error} (all \emph{concrete, printable values}) being channeled out. The input and output value domains are recursively defined by the algebras $InputValue$ and $OutputValue$.


\begin{definition}[semantic \ix{input-output values}]\label{semresultval}\leavevmode
\begin{align*}
   iv \in InputValue &:: =  ~\kw{lit}~|~ \kw{record}\,fi_1:iv_1\dots fi_m:iv_m \\
   ov \in OutputValue &:: = ~\kw{lit}~|~ \kw{record}\,fi_1:ov_1\dots fi_m:ov_m ~|~  \kw{error} \\
 \text{where}~ \kw{lit} \in & Literal, \kw{error} \in ConcreteValue
\end{align*}
$Error$ is the algebraic specification for erroneous program states.
\end{definition}

\begin{remark}[related value domain]\leavevmode
Formally we have that $ InputValue,OutputValue \subset ConcreteValue$. Notice, however, that the latter inclusion breaks slighly down as we extend the $OutputValue$ domain in Definition~\ref{presolve}.
\end{remark}

\begin{remark}[output outcome]\leavevmode
Though not explicitly stated by Yang et al, we have decided only to consider data structures as part of our semantic output value domain and omit (function) closures,
 despite  `$\lambda x \kw{.} e$' expressions technically  are "first class citizens" in Jeeves. Whence only including values which are printable.
\end{remark}

\begin{remark}[implementation]\leavevmode
We do not include an explicit Haskell implementation of the input-output domains. The specification merely serves as an overview of this functionality.
\end{remark}


The second thing to formally consider is the \emph{final set of \ix{solution constraints}} to be resolved upon completion of the evaluation of a print statement.  According to Yang et al~\cite[Fig.~3]{Yang-etal:popl2012}, the dynamic evaluation of a print statement terminates with the application of either of two rules, the (\textsc{e-concretizesat}) or the (\textsc{e-concretizeunsat}). The decision upon which of the rules apply, depends on whether there exists a unique solution `$\mathcal{M}$' (for model) which solves the constrainst set, as expressed by the premise `$\textsc{model}(\Delta,\Sigma \cup \{ \BigG \land \text{context}{=}\upsilon_c \}) = \mathcal{M}$' such that the constraint solution run on the (possibly symbolic) output expression `$\upsilon_v$', instantiates to a (concrete) output value, as the premise  `$c = \mathcal{M} \llbracket \upsilon_v \rrbracket$' suggests.\footnote{A correct premise  would have been `$ true \vdash \langle \emptyset, \emptyset, \mathcal{M} \llbracket \upsilon_v \rrbracket \rangle \rightarrow  \langle \emptyset, \emptyset,c \rangle$' in Yang et al~\cite[Fig.~3,(\textsc{e-concretizesat})]{Yang-etal:popl2012}.}  We formalize the structure `$\textsc{model}(\Delta,\Sigma \cup \{ \BigG \land \text{context}{=}\upsilon_c \})$'   over the elements $\Sigma$ (hard constraints), $\Delta$ (soft constraints), `$\mathcal{G}$' (path condition) and `$\upsilon_c$' (concrete input value, here renamed `$\kappa$').

\begin{definition}[\ix{solution model}]\label{accu-ctr}\leavevmode
{\begin{align*}    
{\begin{aligned}
sol \in Solution :: =  & \textsc{model}\, (\Delta,\Sigma \cup \{ \BigG \land \kw{context}{=}\kappa \}) 
\end{aligned}}
\end{align*}}
\text{where} ~   $\mathcal{G} \in PathCondition$, \, $\kappa \in ConcreteValue$.
\end{definition}

\begin{remark}[\textsc{model} tag]\leavevmode
Because we do not specify a constraint solver in this formalization, we apply the tag \textsc{model} as a \emph{syntactic constructor} with no semantic meaning associated.
\end{remark}


\begin{remark}[default theory property]\leavevmode
 We notice that the constraint set defined by `$(\Delta,\Sigma \cup \{\BigG \land \kw{context} = \upsilon_c \})$'  
 equally forms a (super-normal) default theory.
\end{remark}


\begin{haskell}[solution model]\label{hs:accu-sol}\leavevmode 
The $\textsc{model}$ construction is implemented as the special data type \hask|Solution|, which is equivalent to the 
 \hask|MODEL| container, and a one-to-one implementation of the `$sol$' (concretized constraint set)  quadruple. We notice, that the implementation 
doesn't validate whether \hask|Value| is concrete or not at this point (but the later evaluation rule does). 
\begin{code}
data Solution = MODEL Delta Sigma PathCondition Value                               
type Solutions = [Solution] 

noSolutions :: Solutions
noSolutions = []
\end{code}
\end{haskell}




 
In  accordance with Yang et al, we do not specify constraint resolution explicitly in our formalizations, but tacitly asume that the passage is deferred to later by delegating to an external, off-the-shelf SMT solver ~\cite{DBLP:conf/tacas/MouraB08}. Thus, we have deliberately omitted the specification of the `$c = \mathcal{M} \llbracket \upsilon_v \rrbracket$' clause in our specifications. The ensemble, however, that is fed to the constraint solver, will take 

the form of a new concrete value, which consists of two components, the final accumulated constraint set formalized by  $Solution$ together with the `$\upsilon_v$' (the evaluated output expression feeding into `$\mathcal{M} \llbracket \upsilon_v \rrbracket$' upon constraint resolution).


\begin{definition}[\ix{instantiation}]\label{presolve}\leavevmode   %%%\label{semresultconstr}
Extend the output value algebra of Definition~\ref{semresultval} with an additional form:
\begin{align*}
   ins \in OutputValue  &::= \dots ~|~ \textsc{instantiate} \,(sol, \upsilon) 
\end{align*}
where $sol \in Solution, \upsilon \in Value$
\end{definition}

\begin{remark}[the \textsc{instantiate} tag]\leavevmode
To increase readability, we apply the tag \textsc{instantiate} as a \emph{syntactic constructor} with no semantic meaning associated.
\end{remark}

\begin{haskell}[instantiation]\label{hs:presolve}\leavevmode 
We implement the instantiation concrete value with the special data type \hask|Instantiate| because it is only used at the outermost level of the evaluation.
\begin{code}
data Instantiate =  INSTANTIATE Solution Value 
\end{code}
\end{haskell}


The third thing to formally consider is the \emph{runtime (side) \ix{effects}} from running a \lambdaJ program.
 The original semantics does not include an explicit evaluation rule for a complete \lambdaJ program evaluation, but specify the evaluation of each individual print statement, hinting that constraint solving happens per individual output statement~\cite[Fig.~3]{Yang-etal:popl2012}.  In other words, \lambdaJ only supports \emph{\ix{constraint propagation}} per output posting.\footnote{Constraint propagation means that constraints are accumulated during the course of evaluation.} No constraints gets "carried over" from the runtime evaluation of one output statement to the other.
Consequently, we formalize the effect of running a Jeeves aka \lambdaJ program
to be a list of independent writings to individual output channels. All formalized by the (program) $Effect$ algebra.  


\begin{definition}[program \ix{effect}]\label{effect}\leavevmode
\begin{align*}
{\begin{aligned}      
   \mathcal{E} \in Effect :: =  (output, ins) 
\end{aligned}}
\end{align*}
where ~ $output \in OutputKind$, $ins \in OutputValue$
\end{definition}


\begin{haskell}[\ix{Effects}]\label{hs:effect}\leavevmode 
The Effect algebra is implemented as the special data type \hask|Effect|, which is equivalent to the 
 \hask|EFFECT| container, and a one-to-one implementation of `$output$' and the instantiate output value `$ins$'. 
\begin{code}
data Effect =  EFFECT  Outputkind Instantiate
type Effects = [Effect] 

noEffects :: Effects
noEffects = []
\end{code}
Notice that the concrete value returned uses the dedicated \hask|Instantiate| type.
\end{haskell}












With all preliminary concepts formalized and implemented, we can then proceed by formalizing the actual program runtime semantics.\ In this work, we formulate the \lambdaJ \ix{evaluation semantic} as a \emph{\ix{fixpoint semantics}} in the environment `$\rho$'. Because we have build the semantics with trivial constructs, we know the existence of a  \emph{\ix{least fixpoint}}, which how we are formulating our semantics~\cite{Schmidt:1986}.

In Section~\ref{lamjabssyntax}, we introduced the notion of a \lambdaJ program, to specifically include an explicit (`\kw{letrec}') 
recursion construct at the \lambdaJ level, with the intent of building a recursive function environment in the top-scope, at runtime.
The dynamic semantics of the letrec expression is aimed at being defined as the so-called \emph{\ix{ML
letrec}} with the difference from ML that in \lambdaJ, the \kw{letrec} is defined only 
to appear at the top level of a program~\cite{Milner:1990:DSM:77325}. \footnote{ML's \emph{letrec} combinator defines names by recursive functional equations.}


We are furthermore assuming that all output statements are evaluated \emph{after} 
the program's recursive binding environment has been set up (something which is unclear in the original formalization, where let statements and print statements are presented in any mixed combination in the given examples.) For a more detailed treatment on the recursive binding feature, we refer to Section~\ref{lamjval}.



\begin{definition}[{\ix{program evaluation rule}}]\label{pgmeval}\leavevmode
\begin{gather}
  \tag{p-letrec}
  \dfrac
  {
    \begin{gathered}
     {\begin{aligned}
      & \rho_0, \, \BigG_0 \vdash   \triple{ {\{} {\}}, {\{} {\}}, s_0} \Rightarrow \mathcal{E}_1 \\
      & ~\dots~ \\
      & \rho_0,\, \BigG_0 \vdash \triple{ {\{} {\}} , {\{} {\}}  , s_{m-1}} \Rightarrow \mathcal{E}_m
      \end{aligned}}
    \end{gathered}
  }
  {
    \vdash ~\kw{letrec}~f_1=ve_1 \,\cdots\, f_n=ve_n ~\kw{in} ~ s_0 \,\dots\, s_{m-1} \Rightarrow  (\mathcal{E}_1,\, \dots,\, \mathcal{E}_m )
  }
\\
\intertext{where}  \notag    
{\begin{aligned}
  \rho_0  &=  [f_1 \mapsto {\upsilon}_1,\dots,f_n \mapsto {\upsilon}_n]         &&(1)
\\  
  \text{For all } 0 \leq i \leq n: \quad \upsilon_i
    &=
    {\begin{cases}     
      (ve_i ,\rho_0)  &  \text{if}~ve_i=\lambda x\kw{.}e \, \lor \, ve_i=\kw{thunk}\,e \, \lor \, ve_i=x\\ 
       ve_i           &  \text{otherwise} 
     \end{cases} }                                                                      &&(2)
\\
  \BigG_0 &= {\{} {\}}                                                                  &&(3)
\end{aligned}}
\end{gather}
and ~ $~ f,v, x \in Var, ~ ve \in ValExp, ~ e \in Exp, ~s \in Statement, ~ \mathcal{E} \in Effect$ \\
\end{definition}


\begin{remark}[notation]
To ease readability, we simply state `$ [f_1 \mapsto {\upsilon}_1,\dots,f_n \mapsto {\upsilon}_n]$' for the equivalent `$\epsilon [f_1 \mapsto {\upsilon}_1,\dots,f_n \mapsto {\upsilon}_n]$' notation as expected according to Definition~\ref{def:environments}.
\end{remark}


The program evaluation rule is composed as follows. The static, recursive binding environment `$\rho_0$', specifies the initial  top-level scope of a \lambdaJ\ program. The path condition `$\BigG_0$', specifies the initial  
path constraints before execution of an output statement. In accordance with our early discussion, the execution environment, `$\rho_0,\, \BigG_0$', is the same before the execution of any output statement, regardless of the sequence in which they appear as 1) the recursive environment is assumed to be build up prior to any output statement execution, 2) constraints are not propagated from one output execution to the next.

According to Lemma~\ref{veInvar}, all function bindings, after translation of a Jeeves program to \lambdaJ,  is ensured to be on the (weak head normal) form `$f = ve$', where `$ve$' is a value expression.The "where" clause of the program rule describes when closures, formalized by `$(ve ,\rho)$', are initially build during program evaluation, and when not. As expected, 
this happens when the binding is dispatched to either a $\lambda$-closure, a \kw{thunk}-closure, or a free variable closure. Otherwise, the binding is to either a literal, \kw{context}, or \kw{error}.  


\begin{haskell}[program evaluation rule]\label{hs:pgmeval}\leavevmode
\begin{code}
evalProgram :: FreshVars -> Program -> Effects

evalProgram xs (P_LETREC recbindings outputstms) = effects
  where
     (CONSTRAINTS sigma delta effects) = evalStms xs rho0 emptyPath outputstms noEffects
     rho0 = foldr g empty recbindings     
     g (BIND fi (E_BOOL b)) rho     = insert fi (V_BOOL b) rho  
     g (BIND fi (E_NAT n))  rho     = insert fi (V_NAT n) rho
     g (BIND fi (E_STR s))  rho     = insert fi (V_STR s) rho
     g (BIND fi (E_CONST c)) rho    = insert fi (V_CONST c) rho
     g (BIND fi (E_VAR x)) rho      = insert fi (V_THUNK (E_VAR x) rho0) rho -- closure 
     g (BIND fi (E_LAMBDA x e)) rho = insert fi (V_LAMBDA x e rho0) rho  -- closure
     g (BIND fi (E_THUNK e)) rho    = insert fi (V_THUNK e rho0) rho  -- closure
     g (BIND fi (E_RECORD fes)) rho = insert fi (V_THUNK (E_RECORD fes) rho0) rho  -- closure


evalStms :: FreshVars -> Environment ->  PathCondition -> Statements -> Effects -> Constraints Effects

evalStms xs rho g [] effects = return effects

evalStms xs rho g (stm:stms) effects = do
  effect <- evalStm xs1 rho g stm
  effects2 <- evalStms xs2 rho g stms effects
  return (effect : effects2)
  where
    ~(xs1,xs2) = splitVars xs
\end{code}
\end{haskell}



\begin{definition}[{evaluation of \ix[evaluation of!]{a statement}}]\label{outstmeval}
The big step rule for evaluation of an (output) statement corresponds to the evaluations by the small step rules \textsc{E-ConcretizeExp},  
\textsc{E-ConcretizeSat}, \textsc{E-ConcretizeUnsat} in Yang etal.~\cite[Fig.~3]{Yang-etal:popl2012}, except for the fact that we do \emph{not} 
seek to solve the constraint set to generate a solution `$\mathcal{M}$', but only seek to generate the set of constraints: 
\textsc{model} is here merely a syntactic constructor and has no semantic significance unlike in  Yang etal.~\cite[Fig.~3]{Yang-etal:popl2012}.
\begin{gather}
   \tag{e-concretize}
   \dfrac
   {
    \begin{gathered}
     \rho, \BigG \vdash \triple{\Sigma, \Delta, e_1} \Rightarrow  \triple{\Sigma_1, \Delta_1, \upsilon_1}
     \\
     \rho, \BigG \vdash \triple{\Sigma_1, \Delta_1, e_2} \Rightarrow  \triple{\Sigma_2, \Delta_2, \kappa_2}
    \end{gathered}
   }
   {
    \begin{split}  
   \rho, \BigG & \vdash \triple{\Sigma, \Delta, \kw{output}\,(\kw{concretize}~ e_1 ~\kw{with}~ e_2)} \\
     & \Rightarrow  (\kw{output}, \textsc{instantiate} (\textsc{model}(\Delta_2,\Sigma_2 \cup \{ \BigG \land \text{context}{=}\kappa_2 \}), \upsilon_1))
    \end{split}
   }
 \end{gather}
 \end{definition}

\begin{remark}[extended \kw{concretize} syntax]
Because `\texttt{print}' at the Jeeves source-level
has been generalized to `\texttt{output}' in our formalization (with the tacit assumption that $OutputKind$ carries over to \lambdaJ), we have added  
`\kw{output}' as an explicit tag in our semantics compared to Yang et al~\cite[Fig.~3]{Yang-etal:popl2012} to keep track of the writes to the various kinds of output channels.
\end{remark}




\begin{haskell}[evaluation of a statement]\label{hs:outstmeval}\leavevmode
\begin{code}
evalStm :: FreshVars -> Environment ->  PathCondition -> Statement -> Constraints Effect

evalStm xs rho g (CONCRETIZE_WITH output e1 e2) = 
  (CONSTRAINTS sigma delta effect)
  where
    (CONSTRAINTS sigma delta (c,v)) = do v1 <- evalExp xs1 rho g e1
                                         c2 <- evalExp xs2 rho g e2
                                         return (c2,v1)    -- = (c,v) by pattern matching 
    effect | isConcrete c = EFFECT output (INSTANTIATE (MODEL delta sigma g c) v)
           | otherwise    = error ("Attempt to create MODEL with non-concrete final value"++show c)
    ~(xs1,xs2) = splitVars xs
\end{code}
\end{haskell}
    




\begin{definition}[{evaluation of \ix[evaluation of!]{ expressions}}]\label{generalevalexp}\leavevmode
The judgement $$\rho,\BigG \vdash \triple{\Sigma,\Delta,e} \Rightarrow \triple{\Sigma',\Delta',\upsilon}$$
describes the evaluation of a \lambdaJ\ expression `$e$' to a value `$\upsilon$' in the static environment `$\rho$',  
under pathcondition `$\BigG$', where $\Sigma'$ and $\Delta'$ capture the privacy effects of the evaluation 
on the constraint sets $\Sigma$ and $\Delta$.
\end{definition}

\begin{haskell}[evaluation of expressions]\leavevmode
\begin{code}
evalExp :: FreshVars -> Environment -> PathCondition -> Exp -> Constraints Value
\end{code}
\end{haskell}



We proceed by presenting an environment-based, big step formulation and implementation of the dynamic expression 
semantics of \lambdaJ. The semantics follows the syntax presented in  Definition~\ref{def:jeeves-abs-syn}, and modifies and clarifies 
the  original semantics ~\cite[Figure~3]{Yang-etal:popl2012}.



\begin{definition}[{evaluation of \ix[evaluation of!]{literals and \kw{context}}}]\label{evalcon}
There are no explicit rules for handling literals and \kw{context} in ~\cite[Figure~3]{Yang-etal:popl2012}. We do, however, 
tacitly assume it to be the "identity mapping". The present rule evaluates a subset of simple normal form (expressions): `$b$', `$n$', `$s$', `$c$', `$context$' to the eqivalent normal form (values).
\begin{gather}
  \tag{e-simple}
  \dfrac
  {}
  { \rho , \BigG \vdash \triple{\Sigma, \Delta, \kw{ve} } \Rightarrow \triple{\Sigma, \Delta, \kw{ve}} }
\quad{ 
    \text{where} ~ ve \in \{ b,\, n,\, s ,\, c,\, context \}
     }
\end{gather}
\end{definition}


\begin{haskell}[evaluation of literals and simple expressions]\leavevmode\label{hs:evalcon}
The distinction between (normal form) \emph{expressions} and \emph{values} in Definition~\ref{evalcon} becomes apparent when 
 \hask|E_| constructors are translated into  \hask|V_| constructors. 
\begin{code}
evalExp xs rho g (E_BOOL b)  = return (V_BOOL b)
evalExp xs rho g (E_NAT n)   = return (V_NAT n)
evalExp xs rho g (E_STR s)   = return (V_STR s)
evalExp xs rho g (E_CONST c) = return (V_CONST c)
evalExp xs rho g (E_CONTEXT) = return (V_CONTEXT)
\end{code}
\end{haskell}


\begin{definition}[{evaluation of \ix[evaluation of!]{variable expressions}}]\label{evalvar}

There are no explicit rules for handling variables in ~\cite[Figure~3]{Yang-etal:popl2012}.
The present rule shows how \ix{regular variables}, but also \ix{level variables} are handled in an environment-based semantics.
For further specifics on the role of level variables in the environment, we refer to Definition~\ref{evaldefer}.
\begin{gather}
  \tag{e-var1}
  \dfrac
   {}
   { \rho , \BigG \vdash \triple{\Sigma, \Delta, x} \Rightarrow \triple{\Sigma, \Delta, \rho(x)} }
 \quad{
     \text{where} ~\rho(x) \neq (\kw{thunk}\,e', \rho')
       }
\\[1em]
  \tag{e-var2}
  \dfrac
  { \rho' , \BigG \vdash \triple{\Sigma, \Delta, e' } \Rightarrow \triple{\Sigma', \Delta', \upsilon' } }
  {  \rho , \BigG \vdash \triple{\Sigma, \Delta, x} \Rightarrow \triple{\Sigma', \Delta', \upsilon'} }
  \quad{ 
        \text{where} ~\rho(x) = (\kw{thunk}\,e', \rho')
       }
\end{gather}
\end{definition}

 
\begin{haskell}[evaluation of variable expressions]\leavevmode\label{hs:evalvar}
\begin{code}
evalExp xs rho g (E_VAR x)  = evalExp_VAR (if x `member` rho then rho!x else error ("Undefined!"++show x))
  where  
    evalExp_VAR (V_THUNK e' rho') = evalExp xs rho' g e'  
    evalExp_VAR v                 = return v
\end{code}
\end{haskell}
  
 
\begin{definition}[{evaluation of \ix[evaluation of!]{lambda expressions}}]\leavevmode\label{evallam}
There is no specific rule for lambda expressions alone in Yang etal.~\cite[Fig.~3]{Yang-etal:popl2012}. The present big step rule, however, 
partially correspond to the binding-part of \textsc{E-AppLambda}.  %% and practically always appears in a function application,\cfDefinition~\ref{evalapp}.
In the current semantics, lambda expression evaluation  builds a (concrete) closure normal form with the current  environment and returns it as 
semantic value \cf~Definition~\ref{semval}.

\begin{gather}
  \tag{e-lambda}
  \dfrac
  {}
  { \rho , \BigG \vdash \triple{\Sigma, \Delta, \lambda x\kw{.}e } \Rightarrow \triple{\Sigma, \Delta, (\lambda x\kw{.}e,\rho) } }
\end{gather}
\end{definition}


\begin{haskell}[evaluation of lambda expressions]\leavevmode\label{hs:evallam}
\begin{code}
evalExp xs rho g (E_LAMBDA x e)  =  return (V_LAMBDA x e rho)
\end{code}
\end{haskell}


\begin{definition}[{evaluation of \ix[evaluation of!]{binary operator expressions}}]\leavevmode\label{evalbinop}
The big step rule for evaluation of a binary operator expression corresponds to the evaluations by the small step rules 
\textsc{E-Op}, \textsc{E-Op1}, and \textsc{E-Op2} in Yang etal.~\cite[Fig.~3]{Yang-etal:popl2012}. Definition~\ref{litlextok} 
 specifies the token set of the operator sort that we have included in this formalization.
\begin{gather}
  \tag{e-op1}
  \dfrac
  {
    \begin{gathered}
      \rho, \BigG \vdash \triple{\Sigma, \Delta, e_1} \Rightarrow \triple{\Sigma', \Delta', \kappa_1}
      \\
      \rho, \BigG \vdash \triple{\Sigma', \Delta', e_t} \Rightarrow \triple{\Sigma'', \Delta'', \kappa_2}
    \end{gathered}
  }
  {
    \rho, \BigG
    \vdash \triple{\Sigma, \Delta, e_1~op~e_2}
    \Rightarrow \triple{\Sigma'', \Delta'', \kappa}
  }
  \quad{\kappa \equiv \kappa_1\,op\,\kappa_2 }
\\[1em] % separator between rules.
  \tag{e-op2}
  \dfrac
  {
    \begin{gathered}
      \rho, \BigG \vdash \triple{\Sigma, \Delta, e_1} \Rightarrow \triple{\Sigma', \Delta', \upsilon_1}
      \\
      \rho, \BigG \vdash \triple{\Sigma', \Delta', e_t} \Rightarrow \triple{\Sigma'', \Delta'', \upsilon_2}
    \end{gathered}
  }
  {
    \rho, \BigG
    \vdash \triple{\Sigma, \Delta, e_1~op~e_2}
    \Rightarrow \triple{\Sigma'', \Delta'', \upsilon_1~op~\upsilon_2}
  }
  \quad{\upsilon_1 \equiv \sigma_1 \lor \upsilon_2 \equiv \sigma_2}
\end{gather}
\end{definition}

 
\begin{haskell}[evaluation of binary operator expressions]\leavevmode\label{hs:evalbinop}
Haskell~\ref{hs:lamjexp} shows the implementation of the \hask|Op| binary operator data type.
Notice how we have implemented list concatenation by overloading the definition of \hask|OP_PLUS|. 
\begin{code}
evalExp xs rho g (E_OP op e1 e2) = do 
  v1 <- evalExp xs1 rho g e1
  v2 <- evalExp xs2 rho g e2
  return (evalExp_OP rho g op v1 v2)
  where
    ~(xs1,xs2) = splitVars xs

    evalExp_OP rho g op v1 v2 | isConcrete v1 && isConcrete v2 = (evalOpCC op v1 v2) 
                              | isSymbolic v1 || isSymbolic v2 = (V_OP op v1 v2)
    
    evalOpCC :: Op -> Value -> Value -> Value
    
    evalOpCC OP_PLUS  (V_NAT n1)  (V_NAT n2)  = V_NAT (n1+n2)
    evalOpCC OP_PLUS  (V_STR s1)  (V_STR s2)  = V_STR (s1++s2)
    
    evalOpCC OP_MINUS (V_NAT n1)  (V_NAT n2)  = V_NAT (n1-n2)  

    evalOpCC OP_AND   (V_BOOL b1) (V_BOOL b2) = V_BOOL (b1&&b2)
    evalOpCC OP_OR    (V_BOOL b1) (V_BOOL b2) = V_BOOL (b1||b2)          
    evalOpCC OP_IMPLY (V_BOOL b1) (V_BOOL b2) = V_BOOL ((not b1)||b2)

    evalOpCC OP_EQ  v1 v2     = V_BOOL (v1==v2)
    evalOpCC OP_LESS v1 v2    = V_BOOL (v1<v2)                                                 
    evalOpCC OP_GREATER v1 v2 = V_BOOL (v1>v2)                                                 
\end{code}
\end{haskell}


\begin{definition}[{evaluation of \ix[evaluation of!]{unary operator expressions}}]\leavevmode\label{evaluop}
There are no specific rules concerning unary operator expressions in Yang etal.~\cite[Fig.~3]{Yang-etal:popl2012}. The big step rules, however, 
are simpel to construct and require no further commenting.
Definition~\ref{litlextok} specifies the token set of the operator sort, which currently is the singleton set $\{!\}$ (negation).
\begin{gather}
  \tag{e-uop1}
  \dfrac
  {
    \rho, \BigG \vdash \triple{\Sigma, \Delta, e} \Rightarrow \triple{\Sigma', \Delta', \kappa}
  }
  {
    \rho, \BigG
    \vdash \triple{\Sigma, \Delta, uop~e}
    \Rightarrow \triple{\Sigma'', \Delta'', \kappa'}
  }
  \quad{\kappa' \equiv uop\,\kappa}
\\[1em] % separator between rules.
  \tag{e-uop2}
  \dfrac
  {
    \rho, \BigG \vdash \triple{\Sigma, \Delta, e} \Rightarrow \triple{\Sigma', \Delta', \sigma}
  }
  {
    \rho, \BigG
    \vdash \triple{\Sigma, \Delta, uop~e}
    \Rightarrow \triple{\Sigma'', \Delta'', uop~\sigma}
  }
\end{gather}
\end{definition}

\begin{haskell}[evaluation of unary operator expressions]\leavevmode\label{hs:evaluop}\leavevmode
Definition~\ref{hs:lamjexp} shows the implementation of the \hask|UOp| unary operator data type. 
(Currently a singleton with the \hask|OP_NOT| constructor). 
\begin{code}
evalExp xs rho g (E_UOP uop e) = do
  v <- evalExp xs rho g e
  return (evalExp_UOP rho g uop v)
  where    
    evalExp_UOP rho g uop v | isConcrete v = evalUOpC uop v
                            | isSymbolic v = V_UOP uop v                                  

    evalUOpC :: UOp -> Value -> Value
    evalUOpC OP_NOT (V_BOOL b) = V_BOOL (not b)
\end{code}
\end{haskell}

 
\begin{definition}[{evaluation of \ix[evaluation of!]{conditional expressions}}]\leavevmode\label{evalcond}
The big step rules for evaluation of a conditional expression corresponds to the evaluations by the small step rules \textsc{E-Cond}, 
 \textsc{E-CondTrue}, \textsc{E-CondFalse}, \textsc{E-CondSymT}, and \textsc{E-CondSymF}.
Depending on the conditional, the semantics is implemented in two way: provided it evaluates  to a boolean value, 
then the \kw{if}-expression \emph{behaves in a non-strict fashion}. Provided the conditional evaluates to a symbolic normal form , however,  
then the \kw{if}-expression  \emph{behaves in a strict fashion} as both branches are evaluated to  normal forms. 
The latter underpins the primary reason for symbolic \kw{if}-evaluation: to implement the semantics of \ix{sensitive values}. 
 The evaluation of each branch is in fact performed as separate evaluation steps under (opposing) symbolic/ logical conditions:
 `$\sigma \land \BigG$', and  `$ \neg \sigma \land \BigG $', and the generated constraint sets are  successively being assembled 
into $\Sigma'''$ and $\Delta'''$.\footnote{Because constraints are assembled through set union, the order by which the branches are evaluated is insignificant.}.

\begin{gather}
  \tag{e-cond1}
  \dfrac
  {
    \begin{gathered}
      \rho, \BigG \vdash \triple{\Sigma, \Delta, e_1} \Rightarrow \triple{\Sigma', \Delta', \kw{true}}
      \\
      \rho, \BigG \vdash \triple{\Sigma, \Delta, e_2} \Rightarrow \triple{\Sigma'', \Delta'', \upsilon_2}
    \end{gathered}
  }
  {
    \rho, \BigG
    \vdash \triple{\Sigma, \Delta, \kw{if}~e_1 ~\kw{then}~e_2~\kw{else}~e_3 }
    \Rightarrow \triple{\Sigma'', \Delta'', \upsilon_2}
  }
  \quad{}
\\[1em] % separator between rules.
  \tag{e-cond2}
  \dfrac
  {
    \begin{gathered}
      \rho, \BigG \vdash \triple{\Sigma, \Delta, e_1} \Rightarrow \triple{\Sigma', \Delta', \kw{false}}
      \\
      \rho, \BigG \vdash \triple{\Sigma', \Delta', e_3} \Rightarrow \triple{\Sigma'', \Delta'', \upsilon_3}
    \end{gathered}
  }
  {
    \rho, \BigG
    \vdash \triple{\Sigma, \Delta, \kw{if}~e_1~\kw{then}~e_2~\kw{else}~e_3 }
    \Rightarrow \triple{\Sigma'', \Delta'', \upsilon_3}
  }
  \quad{}
\\[1em] % separator between rules.
  \tag{e-cond3}
  \dfrac
  {
    \begin{gathered}
      \rho, \BigG \vdash \triple{\Sigma, \Delta, e_1} \Rightarrow \triple{\Sigma', \Delta', \sigma}
       \\
     \rho, \sigma \land \BigG \vdash \triple{\Sigma', \Delta', e_2} \Rightarrow \triple{\Sigma'', \Delta'', \upsilon_2}
      \\
     \rho, \neg \sigma \land \BigG \vdash \triple{\Sigma'', \Delta'', e_3} \Rightarrow \triple{\Sigma''', \Delta''', \upsilon_3}
   \end{gathered}
  }
  {
    \rho, \BigG
    \vdash \triple{\Sigma, \Delta, \kw{if}~e_1~\kw{then}~e_2~\kw{else}~e_3 }
    \Rightarrow \triple{\Sigma''', \Delta''',  \kw{if}~\sigma~\kw{then}~\upsilon_2~\kw{else}~\upsilon_3}
  }
  \quad{}
\end{gather}
\end{definition}




The if expession evaluation rule is implemented as follows.

\begin{haskell}[evaluation of conditional expressions]\leavevmode\label{hs:evalcond}\leavevmode
\begin{code}
evalExp xs rho g (E_IF e1 e2 e3) = do 
  v1 <- evalExp xs1 rho g e1
  evalExp_IF v1
  where
    
    -- (e-cond1)
    evalExp_IF (V_BOOL True) = evalExp xs2 rho g e2

    -- (e-cond2)
    evalExp_IF (V_BOOL False) = evalExp xs2 rho g e3

    -- (e-cond3)
    evalExp_IF s1 | isSymbolic s1 = do
      v2 <- evalExp xs21 rho (formulaConjunction (F_IS s1) g) e2
      v3 <- evalExp xs22 rho (formulaConjunction (F_NOT s1) g) e3
      return (V_IF s1 v2 v3)

    ~(xs1,xs2) = splitVars xs                
    ~(xs21,xs22) = splitVars xs2
\end{code}
\end{haskell}


\begin{definition}[{evaluation of \ix[evaluation of!]{application expressions}}]\leavevmode\label{evalapp}
The big step rule for evaluation of an application expression corresponds to the evaluations described by the small step rules \textsc{E-App1},   
\textsc{E-App2}, and \textsc{E-AppLambda} in Yang etal.~\cite[Fig.~3]{Yang-etal:popl2012}. It specifies how function application is carried out 
through \ix{\emph{call-by-value evaluation}}, but with the important difference that 
variable binding during $\beta$-reduction is handled on an \emph{environment basis} ($\rho'[x \mapsto \upsilon_2]$) instead of a 
\emph{substitution basis} ($e[x \mapsto \upsilon]$), \cf Henderson~\cite{H80:FunctionalP}.\footnote{"Environment based" instead of 
"substitution based" semantics prevents unforseable expression expansion, when code is substituted into terms at runtime, thus ensures 
that inductive argumentation can be  applied to prove properties of the semantics.}
The present application rule reformulation is a direct consequence of letting \ix{lexical scoping} be handled with closures as described in Section~\ref{lamjval}.
Finally, we allow the capturing of an erroneous \lambdaJ application upon which the \kw{error} normal form is returned as a semantic result.






\begin{gather}
  \tag{e-app1}
  \dfrac
  {
    \begin{gathered}
      \rho , \BigG \vdash \triple{\Sigma, \Delta, e_1} \Rightarrow \triple{\Sigma', \Delta', \upsilon_1}
      \\
      \rho , \BigG \vdash \triple{\Sigma', \Delta', e_2} \Rightarrow \triple{\Sigma'', \Delta'', \upsilon_2}
      \\
      \rho'[x \mapsto \upsilon_2], \BigG \vdash \triple{\Sigma'', \Delta'', e' } \Rightarrow \triple{\Sigma''', \Delta''', \upsilon_3}
    \end{gathered}
  }
  {
    \rho , \BigG
    \vdash \triple{\Sigma, \Delta, e_1~e_2} \Rightarrow \triple{\Sigma''', \Delta''', \upsilon_3}
  }
  \quad{
        \upsilon_1  \equiv (\lambda x \kw{.} e',\rho')  
       }
\\[1em] % separator between rules.
  \tag{e-app2}
  \dfrac
  {
    \begin{gathered}
      \rho, \mathcal{G} \vdash {\langle \Sigma, \Delta, e_1 \rangle} \Rightarrow {\langle \Sigma', \Delta', \sigma_1 \rangle}
      \\
     \rho, \mathcal{G} \vdash {\langle \Sigma', \Delta', e_2 \rangle} \Rightarrow {\langle \Sigma'', \Delta'', \upsilon_2 \rangle}
    \end{gathered}
  }
  {
    \rho, \mathcal{G}
    \vdash {\langle \Sigma, \Delta, e_1~e_2 \rangle}
    \Rightarrow {\langle \Sigma'', \Delta'', \kw{error} \rangle}
  }
\end{gather}
\end{definition}
  
 
\begin{haskell}[evaluation of application expressions]\leavevmode\label{hs:evalapp}
\begin{code}
evalExp xs rho g (E_APP e1 e2) = do
    v1 <- evalExp xs1 rho g e1
    v2 <- evalExp xs2 rho g e2
    v3 <- evalExp_APP v1 v2
    return v3
  where    
    ~(xs1,xs2,xs3) = splitVars3 xs

    evalExp_APP (V_LAMBDA x e' rho') v2 = do 
           v <- evalExp xs3 (insert x v2 rho') g e'
           return v
   
    evalExp_APP _ _ =  return (V_ERROR)
\end{code}
\end{haskell}
 

\begin{definition}[{evaluation of \ix[evaluation of!]{defer expressions}}]\leavevmode\label{evaldefer} 
The big step rule for evaluation of a defer expression basically corresponds to the evaluations by the small step rules 
\textsc{E-DefeerConstraint}, and \textsc{E-Defer} in Yang etal.~\cite[Fig.~3]{Yang-etal:popl2012}. The current 
defer syntax, \ie `$\kw{defer}~ lx ~\kw{in}~ e$', presents three major differences from the original syntax, as described in Remark~\ref{rem:defer}.
We have modified the \kw{defer} semantics accordingly, by making the evaluation step about "the body" $e$, whilst removing now void evaluation
steps for syntax which is no longer present, notably `$\{e\}$', `$\{\upsilon_c\}$' and `$\kw{default}\,\upsilon_d$'.    
The overall aim of the defer rule is to introduce (level) variables, say `$lx$', and their default values `$\kw{true}$' into the semantics, in 
a way that prevents \ix{name clashing} in the \ix{constraint scopes}. In this setting, we manage (level) variable names `$lx$'  on the environment stack,  
by performing an $\alpha$-renaming with "fresh" variables `$lx'$'. Default values `$\kw{true}$' for variables `$lx'$' are weighing in on any associated 
 (policy) hard constraints by registering as \ix{\emph{soft contraints}} in the collected constraint set `$\Delta  \cup \{\BigG \Rightarrow (lx'{=}\kw{true})\}$'. 
 

\begin{gather}
  \tag{e-defer}
  \dfrac
  {
    \rho[lx\mapsto lx'], \BigG \vdash \triple{\Sigma, \Delta  \cup \{\BigG \Rightarrow (lx'{=}\kw{true})\}, e} \Rightarrow \triple{\Sigma', \Delta', \upsilon}
  }
  {
     \rho, \BigG \vdash \triple{\Sigma, \Delta, \kw{defer}~ lx ~\kw{in}~ e} \Rightarrow
     \triple{\Sigma', \Delta', \upsilon}
  } \quad{\text{\ix{fresh} $lx'$}}
\end{gather}
\end{definition}

To ensure that no bound variables escape into the contraint set we observe the following.

\begin{lemma}[environment scope invariant]\label{envscopeinv}\leavevmode
For every instance of the judgement `$\rho,\mathcal{G} \vdash \langle \Sigma, \Delta, e \rangle \Rightarrow \langle \Sigma', \Delta', \upsilon \rangle$' 
we have that the domain of `$\rho$' contains all free variables in `$e$', and no free variables from~`$\upsilon$'.
\end{lemma}

\begin{proof}
Proven by induction over proofs, where the base cases are the premises of Definition~\ref{pgmeval} and the step is shown for every inference rule.
\end{proof}


The defer expression evaluation rule is implemented as follows.

\begin{haskell}[evaluation of defer expressions]\leavevmode\label{hs:evaldefer}
\begin{code}
evalExp ~(x:xs) rho g (E_DEFER lx e) = do
  unitDeltaConstraints g x (V_BOOL True)
  v <- evalExp xs (insert lx lx' rho) g e
  return v
  where lx' = V_VAR x
\end{code}
\end{haskell}
 

\begin{definition}[{evaluation of \ix[evaluation of!]{assert expressions}}]\leavevmode\label{evalassert}
The big step rule for evaluation of an assert expression corresponds to the evaluations by the small step rules 
\textsc{E-AssertConstraint}, and \textsc{E-Assert} in Yang etal.~\cite[Fig.~3]{Yang-etal:popl2012}. 
The current \kw{assert} syntax, however, has extended the syntax with an `$\kw{in}~e_2$' part, as described in Remark~\ref{rem:assert}.
We have extended the semantics accordingly, by adding a separate evaluation step for `$e_2$'.
The overall aim of \kw{assert} is to introduce policy constraints, given by the (constraint) expression `$e_1$', into the semantics.
This is effectuated through evaluation of  `$e_1$' to a symbolic normal form `$\upsilon_1$', followed by the  
introduction of those as \ix{\emph{hard constraints}} into the constraint environment as `$\Sigma' \cup \{ \BigG  \Rightarrow \upsilon_1\}$'.

\begin{gather}
  \tag{e-assert}
  \dfrac
  {
    \begin{gathered}
     \rho, \BigG \vdash \triple{\Sigma, \Delta, e_1} \Rightarrow \triple{\Sigma', \Delta', \upsilon_1}    
       \\
     \rho, \BigG \vdash \triple{\Sigma' \cup \{ \BigG  \Rightarrow \upsilon_1 \}, \Delta' , e_2} \Rightarrow \triple{\Sigma'', \Delta'', \upsilon_2}         
    \end{gathered}
  }
  {
    \rho, \BigG \vdash \triple{\Sigma, \Delta, \kw{assert}~ e_1 ~\kw{in}~e_2 } \Rightarrow  \triple{\Sigma'', \Delta'', \upsilon_2} 
  }
  \quad{}  %%e_1 \equiv (e \Rightarrow ( l{=}b ) ) 
\end{gather}
\end{definition}



The assert expression evaluation rule is implemented as follows.

\begin{haskell}[evaluation of assert expressions]\leavevmode\label{hs:evalassert}
\begin{code}
evalExp xs rho g (E_ASSERT e1 e2) = do
  v1 <- evalExp xs1 rho g e1
  unitSigmaConstraints g v1
  v2 <- evalExp xs2 rho g e2
  return v2
  where
    ~(xs1,xs2) = splitVars xs
\end{code}
\end{haskell}

 
\begin{definition}[{evaluation of \ix[evaluation of!]{let expressions}}]\leavevmode\label{evallet}
There are no specific rules for \lambdaJ let expressions in Yang etal.~\cite[Fig.~3]{Yang-etal:popl2012}. In the current semantics, we implement 
dynamic let evaluation by \ix{\emph{eager evaluation}}, in that the binding argument `$e_1$', always is evaluated to a normal form `$\upsilon_1$' first, 
then stacked in the binding environment  `$\rho[x_1 \mapsto \upsilon_1]$' as the context in which "the body" `$e_2$' is evaluated. This is reflected 
by the order of the two separate evaluation steps in the following rule.
 


\begin{gather}
  \tag{e-let}
  \dfrac
  {
   \begin{gathered}
      \rho ,\BigG \vdash \triple{\Sigma, \Delta, e_1} \Rightarrow \triple{\Sigma', \Delta',\upsilon_1}
       \\
   \rho[x_1 \mapsto \upsilon_1], \BigG \vdash \triple{\Sigma', \Delta', e_2} \Rightarrow \triple{\Sigma'', \Delta'', \upsilon_2}
    \end{gathered}
  }
  {
    \rho, \BigG
    \vdash \triple{\Sigma, \Delta, ~\kw{let}~x_1 = e_1~\kw{in}~e_2 }
    \Rightarrow \triple{\Sigma'', \Delta'', \upsilon_2}
  }
  \quad{}
\end{gather}
\end{definition}

\begin{haskell}[evaluation of let expressions]\leavevmode\label{hs:evallet}
\begin{code}
evalExp xs rho g (E_LET x1 e1 e2) = do
  v1 <-  evalExp xs1 rho g e1
  evalExp xs2 (insert x1 v1 rho) g e2
  where
    ~(xs1,xs2) = splitVars xs                                                       
\end{code}
\end{haskell}

 
\begin{definition}[{evaluation of \ix[evaluation of!]{record expressions}}]\leavevmode\label{evalrec}
  There are no specific rules for record expressions in Yang etal.~\cite[Fig.~3]{Yang-etal:popl2012}. In the current eager semantics,   
 however, we implement record evaluation \ix{\emph{strictly}} in the field arguments, as a left-to-right evaluation of the field 
bodies $e_0$ \dots $e_n$ to symbolic normal forms $\upsilon_0$ \dots $\upsilon_n$.    


\begin{gather}
  \tag{e-rec}
  \dfrac
  {
    \rho,\BigG \vdash \triple{\Sigma_0,\Delta_0,e_1} \Rightarrow \triple{\Sigma_1,\Delta_1,\upsilon_1}
    ~\cdots~
    \rho,\BigG \vdash \triple{\Sigma_{n-1},\Delta_{n-1},e_n} \Rightarrow \triple{\Sigma_n,\Delta_n,\upsilon_n}
  }
  { 
    \rho,\BigG \vdash \triple{\Sigma_0,\Delta_0, ~\kw{record}~x_1=e_1 \dots x_n=e_n} \Rightarrow \triple{\Sigma_n,\Delta_n, ~\kw{record}~x_1=v_1\dots x_n=v_n}
  }
  \quad{n \geq 0}
\end{gather}

\begin{remark}[empty record]\leavevmode\label{emptyrecord}
We have deliberately allowed $n=0$, as a way to signify the empty record. 
\end{remark}



\end{definition}

\begin{haskell}[evaluation of record expressions]\leavevmode\label{hs:evalrec}
\begin{code}
evalExp xs rho g (E_RECORD fies) = do 
  fivs <- mapM eval1 (insertXss xs fies)
  return (V_RECORD fivs)  
  where                                                      
    insertXss xs [] = []
    insertXss xs ((x,e):xes) = (x,e,xs1) : insertXss xs2 xes where ~(xs1,xs2) = splitVars xs
    
    eval1 (x,e,xs) = do v <- evalExp xs rho g e
                        return (x,v)
\end{code}
\end{haskell}

\begin{definition}[{evaluation of \ix[evaluation of!]{field expressions}}]\leavevmode\label{evalfi}
There are no specific rules for field look up expressions in Yang etal.~\cite[Fig.~3]{Yang-etal:popl2012}. In the current semantics,   
we implement field lookup \ix{\emph{strictly}}, in that the \kw{record} expression part `$e$' of `$e.f_i$' is evaluated completely to symbolic normal form.
If the evaluation renders a `\kw{record}' with all fields on normal form, the indicated field content is returned as semantic value. Otherwise, 
we return the normalized field lookup entity `$\sigma\kw{.}fi$' as semantic value.

\begin{gather}
  \tag{e-field1}
  \dfrac{
    \rho,\BigG ~\vdash~ \triple{\Sigma, \Delta, e} ~\Rightarrow~ \triple{\Sigma_1, \Delta_1, \kw{record}~ fi_1=v_1~\dots~fi_n=v_n}
  }
  { \rho,\BigG ~\vdash~ \triple{\Sigma, \Delta, e\kw{.}fi_i} ~\Rightarrow~ \triple{\Sigma_1,\Delta_1, v_i} }
\\[1em]
  \tag{e-field2}
  \dfrac{
    \rho,\BigG ~\vdash~ \triple{\Sigma, \Delta, e} ~\Rightarrow~ \triple{\Sigma_1, \Delta_1, \sigma}
  }
  { \rho,\BigG ~\vdash~ \triple{\Sigma, \Delta, e\kw{.}fi} ~\Rightarrow~ \triple{\Sigma_1,\Delta_1, \sigma\kw{.}fi } }
  \quad{ \sigma \neq \kw{record}\,fi_1=v_1\,\dots\,fi_n=v_n }
\end{gather}
\end{definition}

\begin{haskell}[evaluation of field expressions]\leavevmode\label{hs:evalfi}
\begin{code}
evalExp xs rho g (E_FIELD e fi) = do
  v1 <- evalExp xs rho g e
  return (evalVar_FIELD v1)
  where
    evalVar_FIELD (V_RECORD fivs)  = head [v' | (fi',v') <- fivs, fi'==fi]
    evalVar_FIELD v                = (V_FIELD v fi)
\end{code}
\end{haskell}



 
Like the semantics by Yang et al~\cite{Yang-etal:popl2012}, we observe that the evaluation semantics constitutes a deterministic proof system.



 
Finally, we illustrate the program evaluation rule with the first of our canonical examples from Example~\ref{confmanage}, based on the translation to \lambdaJ in Example~\ref{ntp2}. Because of the shere size, however, we only show selected parts of the proof tree. 


\begin{example}[Name policy program evaluation]\label{namepoleval}\leavevmode

The main judgement has the following form:
\begin{gather}
  \tag{p-letrec}
  \dfrac
  {
    \begin{gathered}
     {\begin{aligned}
      & \rho_0, \, \BigG_0 \vdash   \triple{ {\{} {\}}, {\{} {\}}, \kw{print}(\kw{concretize}\,msg\,\kw{with}\,alice)} \Rightarrow \mathcal{E}_1 \\
      & \rho_0,\, \BigG_0 \vdash \triple{ {\{} {\}} , {\{} {\}}, \kw{print}(\kw{concretize}\,msg\,\kw{with}\,bob)} \Rightarrow \mathcal{E}_2
      \end{aligned}}
    \end{gathered}
  }
  {
\begin{gathered}
   {\begin{aligned}
    \vdash ~\kw{letrec}~\text{name} \kw{=} ve_1, \text{msg} \kw{=} ve_2 ~\kw{in} ~ & \kw{print}(\kw{concretize}\,msg\,\kw{with}\,alice) \\
                                                                        & \kw{print}(\kw{concretize}\,msg\,\kw{with}\,bob)
                            \Rightarrow  \mathcal{E}_1,\,\mathcal{E}_2  &
   \end{aligned}}
 \end{gathered}
}
\\
\intertext{where}  \notag    
{\begin{aligned}
  \rho_0  &=  [\text{name} \mapsto (ve_1,\rho_0),\,\text{msg} \mapsto(ve_2,\rho_0) ] \\  
  \BigG_0 &= {\{} {\}}                                                                 
\end{aligned}}
\\
\intertext{and}  \notag    
{\begin{aligned}
   ve_1 &=  \kw{thunk} ( \kw{defer}\, a\, \kw{in}\, (\kw{assert}\, ( !(\kw{context} = alice) => (a=false))\, in\,  \llbracket \texttt{<}"Anonymous" \texttt{|} "Alice" \texttt{>} (a)\rrbracket )) \\
   ve_2 &=  \kw{thunk}\,("Author~ is~ " + \,name) \\                                                                
\end{aligned}}
\\
\intertext{and}  \notag 
{\begin{aligned}
\llbracket \texttt{<}"Anonymous" \texttt{|} "Alice" \texttt{>}(a)\rrbracket &  = \kw{if}~a~\kw{then}~"Alice"~\kw{else}~"Anonymous"
\end{aligned}}
\end{gather}
\end{example}





\section{\ix{Running a Jeeves program}}\label{runjeeves}    %% pertaining to -- i henhold til.





In this section, we show how to run a Jeeves program as it pertains to this document as a literate Haskell implementation of a Jeeves
compiler and a \lambdaJ evaluation engine. The main program is the \emph{Jeeves program evaluator}.  It consists of a parsing step,
which converts from the Jeeves source language to \lambdaJ abstract syntax, followed by an evaluation phase of the generated \lambdaJ
terms \cf Figure~\ref{run-jeeves}. We also provide a way to run just the compile step to \lambdaJ terms (\ie, without the output
part in Figure~\ref{run-jeeves} as the input part is a build-in feauture of Jeeves). We are dedicating the remainder of the section to
show how to run the canonical ``Naming Policy'' program from Figure~\ref{fig:testp1}, and ``Conference Management System'' program from 
Figure~\ref{fig:testp2}, and how to interpret the results.


 
At first, we illustate the beginning of a session with the Hugs Haskell system~\cite{HugsHaskell}, where this 
\ix{literate program}~\cite{Rose:github2014} is loaded with the command \texttt{:load "jeeves-constraints.lhs"}. 
(The program also runs with Glasgow Haskell.)
In the remainder of this section, we will tacitly assume that loading has been successfully completed.


\begin{verbatim}
__   __ __  __  ____   ___      _________________________________________
||   || ||  || ||  || ||__      Hugs 98: Based on the Haskell 98 standard
||___|| ||__|| ||__||  __||     Copyright (c) 1994-2005
||---||         ___||           World Wide Web: http://haskell.org/hugs
||   ||                         Bugs: http://hackage.haskell.org/trac/hugs
||   || Version: September 2006 _________________________________________

Haskell 98 mode: Restart with command line option -98 to enable extensions

Type :? for help
Hugs> :load "jeeves-constraints.lhs"
Main> 
\end{verbatim}



A Jeeves program (and input) is evaluated with the invocation of the Jeeves evaluator by giving the command:  
 $$ \hask|evaluateFile|~\text{<}\textit{filename} \text{>}$$

which results in a sequence of (non-interfeering) `\hask|Effects|' in accordance with  Definition~\ref{pgmeval} and Haskell~\ref{hs:pgmeval}. 
In appendix~\ref{prettyhs} it is outlined how the effect output is formatted.
The implementation of \ix[evaluateFile@]{\texttt{evaluateFile}} is reflected in the following code snippet.


\begin{haskell}[Jeeves evaluator]\label{hs:topeval}\leavevmode
\begin{code}
-- ------------------
-- TOP EVALUATOR

evaluate :: String -> Effects

evaluate jeeves = effects
  where
    programParse = parse (programParser xs1) jeeves
    effects = if null programParse then noEffects else evalProgram xs2 (fst (head programParse))
    (xs1,xs2) = splitVars vars

evaluateFile filename = do jeeves <- readFile filename   -- IO utility
                           putStr (show (evaluate jeeves))
\end{code}
\end{haskell}



A Jeeves program (with input) is parsed/translated with the invocation of the Jeeves parser by giving the command:  
$$ \hask|parseFile|~\text{<}\textit{filename}\text{>} $$  
The parser output is a
\lambdaJ\ program that follows the specification in
Definition~\ref{transjpgm} and Haskell~\ref{hs:transjpgm}. In
appendix~\ref{prettyhs} it is outlined how the \lambdaJ\ output is
formatted in Haskell. The code for \ix[parseFile@]{\texttt{parseFile}}  is listed in the Haskell~\ref{parserframework} framework.



The program (with input) format has to adhere to the syntax specified in Definition~\ref{def:jeeves-concr-syn}, 
as illustrated by the Jeeves program examples in Figure~\ref{fig:testp1} and Figure~\ref{fig:testp2}.
In the following, we tacitly assume that two files have been created, \texttt{testp1.jeeves} and \texttt{testp2.jeeves}, which respectively 
contain those programs.



The (formatted) program output from running the program is a list of  effects where each effect, according to  Definition~\ref{outstmeval}, is formally 
described by $ (\kw{output}, \textsc{instantiate} (\textsc{model}(\Delta,\Sigma \cup \{ \BigG \land \text{context}{=}\kappa \}), \upsilon))$.
This output is formatted as follows by our implementation:
\begin{verbatim}
  Effect "output"
     SOFT CONSTR = ...
     HARD CONSTR MODEL = ...
     SYMBOLIC VALUE = ...
\end{verbatim}
where `Effect' is a keyword, `output' prints the value of $\kw{output}$, `SOFT CONSTR = ...' prints the soft constraint set $\Delta$, `HARD CONSTR MODEL = ...'  prints the instantiated hard constraint set `$\Sigma\cup \{ \BigG \land \text{context}{=}\kappa \}$', and  `SYMBOLIC VALUE = ...' prints the symbolic value $\upsilon$.
The order in which the (non-interferring) effects appear, reflects directly the order in which the print statements appear in the Jeeves program. We obviously has chosen to keep that ordering in the formatted program output, which is printed as a vertical list of the form `[ <\emph{effect}>,\, \dots ,\,  <\emph{effect}> ]' where `<\emph{effect}>' is formatted as described above.  We depict how to run and what the formatted program output looks like for the Naming Policy Program from Figure~\ref{fig:testp1}. According to the theoretical program evaluation in Example~\ref{namepoleval}, the program \emph{exactly} evaluates to the expected constraint sets and values!

\begin{verbatim}
Main> evaluateFile "Tests/testp1.jeeves"
[
  EFFECT "print"
    SOFT CONSTR= {} ∪ {True ⇒ x10=true},
    HARD CONSTR MODEL = {} ∪ {True ⇒ (¬(context='alice') ⇒ (x10=false))} 
                              ∪ {True ∧ context='alice'}
    SYMBOLIC VALUE = ('Author is ' + (if x10 then 'Alice' else 'Anonymous'))
  ,
  EFFECT "print"
    SOFT CONSTR = {} ∪ {True ⇒ x20=true},
    HARD CONSTR MODEL = {} ∪ {True ⇒ (¬(context='alice') ⇒ (x20=false))} 
                              ∪ {True ∧ context='bob'}
    SYMBOLIC VALUE = ('Author is ' + (if x20 then 'Alice' else 'Anonymous'))
  ]
\end{verbatim}

We also depict how to run and what the formatted program output looks like for the Conference Management Policy program from Figure~\ref{fig:testp2}.
Eventhough we have not made a formal proof of the expected constraint sets and values, the result of the run at this point is relatively convincing according to common sense.  

\begin{verbatim}
Main> evaluateFile "Tests/testp2.jeeves"
[
  EFFECT "print"
    SOFT CONSTR = {} ∪ {True ⇒ x90=true} ∪ {True ⇒ x58=true} ∪ {True ⇒ x26=true},
    HARD CONSTR MODEL = {} 
         ∪ {True ⇒ (¬(((context.viewer.role=Reviewer) 
                      ∨ (context.viewer.role=PC)) ∨ (context.stage=Public)) 
                    ⇒ (x90=false))} 
         ∪ {True ⇒ (¬(((if x58 then 'Alice' else 'Anonymized')=context.viewer.name) 
                      ∨ ((context.stage=Public) ∧ ¬((if x90 then Accepted else 'none')='none'))) 
                    ⇒ (x58=false))} 
         ∪ {True ⇒ (¬(((context.viewer.name =(if x58 then 'Alice' else 'Anonymized')) 
                      ∨ (context.viewer.role=Reviewer)) 
                      ∨ (context.viewer.role=PC))
                      ∨ ((context.stage=Public) ∧ ¬((if x90 then Accepted else 'none')='none'))) 
                    ⇒ (x26=false))} 
         ∪ {True ∧ context=(record viewer=(record name='Alice' role=PC) stage=Public) }
    SYMBOLIC VALUE = (record title=(if x26 then 'MyPaper' else '') 
                             author=(if x58 then 'Alice' else 'Anonymized') 
                             accepted=(if x90 then Accepted else 'none')
                     )
  ,
  EFFECT "print"
    SOFT CONSTR = {} ∪ {True ⇒ x180=true} ∪ {True ⇒ x116=true} ∪ {True ⇒ x52=true},
    HARD CONSTR MODEL = {} 
         ∪ {True ⇒ (¬(((context.viewer.role=Reviewer) 
                      ∨ (context.viewer.role=PC)) ∨ (context.stage=Public)) 
                    ⇒ (x180=false))} 
         ∪ {True ⇒ (¬(((if x116 then 'Alice' else 'Anonymized')=context.viewer.name) 
                     ∨ ((context.stage=Public) ∧ ¬((if x180 then Accepted else 'none')='none'))) 
                    ⇒ (x116=false))} 
         ∪ {True ⇒ (¬(((context.viewer.name=(if x116 then 'Alice' else 'Anonymized')) 
                      ∨ (context.viewer.role=Reviewer)) 
                      ∨ (context.viewer.role=PC)) 
                      ∨ ((context.stage=Public) 
                        ∧ ¬((if x180 then Accepted else 'none')='none'))) 
                    ⇒ (x52=false))} 
         ∪ {True ∧ context=(record viewer=(record name='Bob' role=Reviewer) stage=Public)}
    SYMBOLIC VALUE = (record title=(if x52 then 'MyPaper' else '') 
                             author=(if x116 then 'Alice' else 'Anonymized') 
                             accepted=(if x180 then Accepted else 'none')
                     )
  ]
\end{verbatim}


The formatted output from invoking the Jeeves parser is a \lambdaJ\ program that follows the specification in Definition~\ref{transjpgm} and Haskell~\ref{hs:transjpgm}. In appendix~\ref{prettyhs} it is outlined how the \lambdaJ\ output is formatted. We depict how to run the Jeeves parser and what the formatted \lambdaJ\ program looks like for the Naming Policy Program from Figure~\ref{fig:testp1}. According to the theoretical program translation in Example~\ref{ntp2}, the program \emph{exactly} parses to the expected \lambdaJ\ terms!

\begin{verbatim}

Main>  parseFile "Tests/testp1.jeeves"
[(
letrec
 name = thunk ( (defer a in (assert (¬ (context='alice') ⇒ (a=false)) in 
                                            (if a then 'Anonymous' else 'Alice'))) );
 msg = thunk ( ('Author is '+name) );
in
 print: concretize msg with 'alice' ;
 print: concretize msg with 'bob' ;
,"")]
\end{verbatim}

Because of the verbose nature of the parsing step, we will sidestep the equivalent outcome from parsing the Conference Mangagement Program. 


\section{Conclusion}\label{concl}

We have presented the first complete implementation of the \emph{Jeeves evaluation engine}. "Complete" in the sense that the 
evaluation of a program written in Jeeves syntax is in fact defined in terms of the \lambdaJ\  evaluation semantics, as is directly 
reflected in  our implementation. "Not-complete", however, in the sense that a static (type) verification step currently has been omitted. 
As part of the process, we have specifically \emph{obtained a tool that is able to generate privacy constraints for a given Jeeves program}.
The actual constraint solving phase, however, has in accordance with Yang et al~\cite{Yang-etal:popl2012} been assumed to happen at a later 
time and is thus not part of our formalization efforts directly. 

The implementation consists the following Haskell components: 
\begin{itemize}
\item abstract Haskell type definitions to define a concrete Jeeves syntax as well as the \lambdaJ\ syntax; 
\item an LL(1)-parser that builds abstract \lambdaJ\ syntax trees from the Jeeves source-language, thus translating Jeeves to \lambdaJ\ terms;  
\item a \lambdaJ-interpreter, implementing the operational evaluation semantics of \lambdaJ;
\item an implementation of constraint evaluation as monadic operations on a monadic constraint environment. 
\end{itemize}
With this implementation, we were able to both run and parse the canonical examples from Figure~\ref{fig:testp1}   and Figure~\ref{fig:testp2} as they (almost) appear in the original paper by Yang et al~\cite{Yang-etal:popl2012} (after some syntactical corrections and adjustments) with the expected results. All in an easy-to-use fashion as explained in Section~\ref{runjeeves}. 
We have achieved an elegant,  
yet precise program documentation by making use of Haskells' ``literate'' programming feature to incorporate  the theoretical part of 
the report together with the actual program, ie, the source  \LaTeX\ of this report also serves as the source code of the program, as accounted for in Notation~\ref{literatehs}. 



We have corrected a number of inconsistencies and shortcomings in the original syntax and semantics, together with certain limitations, 
 in order to support an implementation, notably: 
\begin{itemize}
\item added explicit syntax for a Jeeves and \lambdaJ\ program;
\item introduced explicit semantics for the \kw{letrec} recursive operator in \lambdaJ\;
\item only allowing recursive functions at the top-level of a program;
\item disallowing recursively defined policies; 
\item introduced explicit semantics for output side-effects; 
\item reformulated the dynamic operational semantics of \lambdaJ\ to one that is entirely de-compositional and non-substitutional for convincingly proving program and privacy properties.
\item identified the constraint set handling as being monadic with policies as the only constructs with side-effects on the constraint set (as expected).
\end{itemize}

We have published the implementation as a github project~\cite{Rose:github2014}.


\section{Future Directions}\label{futurama}


First of all, it is desirable to have the implementation "hooked up" to a constraint solver (with a Haskell interphase).

Even though the interpreter component of the implementation has the advantage of serving as a "proof of concept" as much as a practical,
 and theoretically transparent tool (the implementation of an operational semantics is by definition an interpreter), efficiency is of inherent concern.
 Efficiency can, in fact, be improved considerably by replacing the \lambdaJ\ interpreter with a compilation step, that translates \lambdaJ\ syntax trees
to some efficient target code, whilst incorporating the semantic evaluation rules directly. Joelle Despeyreaux, for example, has outlined 
how to perform such a systematic translation from mini-ML, while incorporating the languages' operational semantics~\cite{Des86lics}. 

Redefining some of the Haskell parser mechanisms such  as "++" is another area of optimization gains to explore. Because many of these pre-defined 
parser mechanisms allow backtracking, we have not been able to optimize our parser further, other than ensuring that the grammar productions that
are parsed is on LL(1) form, which we found is not enough to avoid backtracking completely.

A study of how to optimize on the generated constraints prior to any automated constraint solving phase, could possible increase the efficiency (and correctness) of thereof.




\appendix

\section{Discrepancies from the original formalization}\label{impldesign}


In this section, we list the modifications and formalization decisions we have made compared to Yang et al~\cite{Yang-etal:popl2012} in order to clarify the syntax and semantics sufficiently to support an implementation.


\begin{discrepancy}[Jeeves syntax]
The original abstract syntax \cf Yang et al~\cite[Fig.~1]{Yang-etal:popl2012} has been extended in several ways \cf Definition~\ref{def:jeeves-abs-syn}:
\begin{itemize}
\item the syntax of a program has been made explicit,  
\item let statements are made an explit part of the program syntax,
\item let statements only appear at the top-level of a program,
\item a policy expression must contain an "\texttt{in}" part,
\item the syntax of let expressions has been made explicit,
\item the syntax for expression sequences has been made explicit,
\item generalized level expressions has been made explicit, 
\item record and field expressions have been made explicit.
\end{itemize}

As a consequence of only allowing (recursively defined) let statements at the top-level of a Jeeves program, we obtain the following notable limitations:

\begin{itemize}
\item we disallow recursively defined functions in symbolic values, 
\item we disallow cyclic data structures.
\end{itemize}


Finally, we have added a \emph{\ix{concrete syntax}} for Jeeves programs in Definition~\ref{def:jeeves-concr-syn}.

\end{discrepancy}



\begin{discrepancy}[\lambdaJ\ syntax]
The original abstract syntax \cf Yang et al~\cite[Fig.~2]{Yang-etal:popl2012} has been extended in several ways \cf Definition~\ref{lamjpgm}, Definition~\ref{lamjstat}, Definition~\ref{lamjexp}, as well as Definition~\ref{semval}:

\begin{itemize}
\item  the syntax of a program has been made explicit,
\item  the recursive combinator `\kw{letrec}' has been added as a statement,
\item  the recursive combinator `\kw{letrec}' has been removed as an expression,
\item  output statements have been generalized,
\item  an explicit \kw{output} tag to concretize statements has been added,
\item  the notion of a thunk expression has been added,
\item  the defer expression has been simplified (to reflect the translation),
\item  the assert expressions must contain an "\kw{in}" part, 
\item  the unit (`()') entity has been removed, 
\item  records have been added as expressions (when their fields are expressions),
\item  field look-up has been added as an expression,
\item  concrete and symbolic values are not automatically defined as expressions.
\end{itemize}

As a consequence of only allowing letrec and output statements at the top-level of a \lambdaJ\ program, we obtain the following notable limitations:

\begin{itemize}
\item a static, recursive scope of a program is only established at the top-level, 
\item a static, recursive scope of a program is established globally prior to side effect statements (output).
\end{itemize}

As mentioned, the category of concrete and symbolic normal forms is defined separately, though some syntactic entities appear both as an expression and as a value \cf Definition~\ref{semval}:

\begin{itemize}
\item closures have been added as concrete values,
\item strings and constants have been added as concrete values,
\item records over concrete fields have been added as concrete value,
\item records over symbolic fields have been added as symbolic value,
\item field look-up over a symbolic record has been added as a symbolic value,
\end{itemize}

\end{discrepancy}



\begin{discrepancy}[\lambdaJ translation]
The original translation  \cf Yang et al~\cite[Fig.~6]{Yang-etal:popl2012} has been extended in several ways \cf Definition~\ref{transjpgm}, Definition~\ref{transjexp}, and Definition~\ref{litlextok3}:

\begin{itemize}
\item the translation of a Jeeves program has been added, 
\item the translation of expression sequences has been added,
\item the translation of if expressions has been added,
\item the translation of let expressions has been added,
\item a generalization of the level expression  translation has been added, 
\item the (trivial) "\kw{default}" part has been removed,
\item binary operator expression translation has been added,
\item function application translation has been added,
\item record translation has been added,
\item field look-up translation has been added,
\item translation of literals and `\kw{context}' has been added,
\item translation of logical (unary) negation has been added,
\item translation of (syntactic sugary) paranthesis has been added.
\end{itemize}

\end{discrepancy}


\begin{discrepancy}[evaluation semantics]
The original evaluation semantics \cf Yang et al~\cite[Fig.~3]{Yang-etal:popl2012} has been extended and modified in several ways \cf Definition~\ref{pgmeval}, Definition~\ref{outstmeval} , and Definition~\ref{generalevalexp}:

\begin{itemize}
\item adding the notion of a binding environment (to manage evaluation scopes),
\item reformulating the semantics as a least fixpoint semantics in the environment,
\item formulating an evaluation semantics of a program (as a series of effects),
\item reformulation from small-step to big-step semantics,
\item reformulation from non-compositional to compositional semantics,
\item reformulation from substitution-based to non-substitution based semantics,
\item adding evaluation semantics for variable lookup,
\item adding evaluation semantics for unary operation,
\item added level variable handling to happen by the binding environment,
\item added evaluation semantics for let expressions,
\item added  evaluation semantics for record expressions,
\item added  evaluation semantics for field look-up expressions.
\end{itemize}

We have furthermore added formalizations for the \lambdaJ input-output domains (Definition~\ref{semresultval}), and for the pre-constraint-solve output effect from running a program prior to any constraint solving (Definition~\ref{hs:presolve}).
\end{discrepancy}








 









\section{Additional code}\label{appExtraCode}

In this appendix we include various fragments of code that were not deemed key to the main presentation.

\begin{haskell}[Literal lexical token parsers]\leavevmode\label{hs:litlextokpars}
\begin{code}
spaces = many myspace  -- white space and Haskell style comments in Jeeves
  where             
    myspace = sat isSpace
              +++
              (do word "--"
                  many (sat (/= '\n'))
                  return ' ')

ident :: Parser String  -- a lower case letter followed by alphanumeric chars
ident =  do xs <- ident2   
            if (isKeyword xs) then failure else return xs
  where
    ident2 = do x <-  sat isLower
                xs <- many (sat isAlphaNum)
                return (x:xs)

isKeyword idkey = elem idkey keywords
keywords = ["top","bottom","if","then","else","lambda",
            "level","in","policy","error","context","let",
            "true","false","print","sendmail"]

nat :: Parser Int  -- a sequence of digits
nat = do xs <- many1 (sat isDigit)
         return (read xs)   

string :: Parser String  -- strings can be in "" or ''.
string = do sat (== '"')
            s <- many (sat (/= '"'))
            sat (== '"')
            return s
         +++ 
         do sat (== '\'')
            s <- many (sat (/= '\''))
            sat (== '\'')
            return s

constant  = do x <- sat isUpper
               xs <- many (sat isAlphaNum)
               return (x:xs)
\end{code}
\end{haskell}

\begin{haskell}[parser framework]\leavevmode\label{parserframework}
\begin{code}
data Parser a = PARSER (String -> [(a, String)]) 

parse :: Parser a -> String -> [(a,String)]
parse (PARSER p) inp = p inp

parseFile filename = do jeeves <- readFile filename    -- IO utility
                        putStr (show (parse (programParser vars) jeeves))

instance Monad Parser where
  return v = PARSER (\inp -> [(v,inp)])
  p >>= f = PARSER (\inp -> case parse p inp of
                              [] -> []
                              [(v,out)] -> parse (f v) out)

failure :: Parser a
failure = PARSER (\inp -> [])

success :: Parser ()
success = PARSER (\inp -> [((),inp)]) 
  
item :: Parser Char
item = PARSER (\inp -> case inp of 
                        "" -> []
                        (x:xs) -> [(x,xs)] )

-- choice operator
(+++) :: Parser a -> Parser a -> Parser a   
p +++ q = PARSER (\inp -> case parse p inp of
                            [] -> parse q inp
                            [(v,out)] -> [(v,out)])                                            

-- token parser builder 
wordToken :: String -> a -> Parser a  -- builds a token parser for a word tok to return r on success
wordToken tok r = do token (word tok)
                     return r

-- derived primitives                
sat :: (Char -> Bool) -> Parser Char
sat p = do x <- item                       
           if p x then return x else failure

-- basic token definitions
token :: Parser a -> Parser a                      
token p = do spaces  
             v <- p
             spaces
             return v

word :: String -> Parser String    -- parses just the argument characters, incl. white spaces
word []     = return []
word (c:cs) = do sat (== c)
                 word cs
                 return (c:cs)

-- generic combinators
many :: Parser a -> Parser [a]
many p = many1 p +++ return []

many1 :: Parser a -> Parser [a]
many1 p = do v <- p
             vs <- many p
             return (v:vs)

optional :: Parser a -> Parser [a]
optional p = optional1 p +++ return []

optional1 p = do v <- p
                 return [v]

manyParser :: (FreshVars -> Parser a) -> FreshVars -> Parser b -> Parser [a]
manyParser p xs sp = manyParser1 p xs sp +++ return []

manyParser1 p xs sp = (do v <- p xs1
                          vs <- manyParserTail p xs2 sp
                          return (v:vs))
  where (xs1,xs2) = splitVars xs                                                                  

manyParserTail p xs sp = (do sp                      -- parses separation tokens like ; , . etc   
                             v <- p xs1
                             vs <- manyParserTail p xs2 sp
                             return (v:vs))
                         +++
                         return []
  where (xs1,xs2) = splitVars xs                                                                      
\end{code}
\end{haskell}

\begin{haskell}[pretty-printing \lambdaJ syntax]\leavevmode\label{prettyhs}
\begin{code}
instance Show Effect where
  show (EFFECT output (INSTANTIATE (MODEL delta sigma g c) v)) = 
    "\n  EFFECT " ++ show output ++
    "\n    SOFT CONSTR = " ++ show delta ++ ","  ++
    "\n    HARD CONSTR INST = " ++ show sigma ++ " ∪ {" ++ show g ++ " ∧ context=" ++ show c ++ " }" ++ 
    "\n    SYMBOLIC VALUE = " ++ show v ++ "\n  "

instance (Show a)=>Show (Constraints a) where
  show (CONSTRAINTS sigma delta e) =
    "CONSTRAINTS" ++ 
    "\n  SIGMA = " ++ show sigma ++
    "\n  DELTA = " ++ show delta ++
    "\n  " ++ show e

instance Show Value where   -- pretty printing lambda J values
  show (V_BOOL b)          = if b then "true" else "false"  
  show (V_NAT i)           = show i  
  show (V_STR s)           = "'" ++ s ++ "'"  
  show (V_CONST s)         = s  
  show (V_ERROR)           = "error"
  show (V_LAMBDA x e rho)  = "(\\"++show x++"."++show e++",RHO)"
  show (V_THUNK e rho)     = "(thunk RHO)"
  show (V_RECORD fivs)     = "(record" ++ (if null fivs then "" else foldr1 (++) (map (\(fi,e)-> (" "++show fi++"="++show e)) fivs)) ++ ")"
  show (V_VAR x)           = show x 
  show (V_CONTEXT)         = "context"   
  show (V_OP op v1 v2)     = "("++show v1++show op++show v2++")"   
  show (V_UOP uop v)       = show uop++show v
  show (V_IF v1 v2 v3)     = "(if " ++ show v1 ++ " then " ++ show v2 ++ " else " ++ show v3 ++ ")"
  show (V_FIELD v fi)      = show v++"."++show fi

instance Show Exp where -- pretty printing lambda J expressions
  show (E_BOOL True)      = "true"
  show (E_BOOL False)     = "false"
  show (E_NAT n )         = show n
  show (E_STR s )         = "'" ++ s ++ "'"  -- todo: remove escape quotes 
  show (E_CONST s)        =  s               -- no quotes in a constant by definition            
  show (E_VAR v )         = show v 
  show (E_CONTEXT)        = "context"
  show (E_LAMBDA v e)     = "lambda " ++ (show v) ++ "." ++ (show e)  
  show (E_THUNK e)        = "thunk " ++ "( " ++ (show e) ++ " )"
  show (E_OP op e1 e2)    = "(" ++ show e1 ++ show op ++ show e2 ++ ")"  
  show (E_UOP uop e)      = show uop ++ " " ++ show e
  show (E_IF e1 e2 e3)    = "(if " ++ show e1 ++ " then " ++ show e2 ++ " else " ++ show e3 ++ ")" 
  show (E_APP e1 e2)      = "(" ++ show_APP e1 ++ " " ++ show e2 ++ ")"
    where
      show_APP (E_APP e1 e2)  = "("++ show_APP e1 ++ " " ++ show e2 ++ ")"
      show_APP e              = show e
  show (E_DEFER v e)      = "(defer " ++ show v ++ " in " ++ show e ++ ")"  
  show (E_ASSERT e1 e2)   = "(assert " ++ show e1 ++ " in " ++ show e2 ++ ")"  
  show (E_LET x e1 e2)    = "(let " ++ show x ++ " = " ++ show e1 ++ " in " ++ show e2 ++ ")"  
  show (E_RECORD fies)    = "(record" ++ (if null fies then "" else foldr1 (++) (map (\(fi,e)-> (" "++show fi++"="++show e)) fies)) ++ ")"
  show (E_FIELD e fi)     = show e ++ "." ++ show fi

instance Show Binding  where
  show (BIND x e) = " " ++ show x ++ " = " ++ show e ++ ";\n"

instance Show Statement where
  show (CONCRETIZE_WITH output e1 e2) = " " ++ output ++ " (concretize " ++ show e1 ++ " with " ++ show e2 ++ ") ;\n"

instance Show Program where
  show (P_LETREC ls ps) = "\nletrec\n" ++ concat (map show ls) ++ "in\n" ++ concat (map show ps)

instance Show Op where
  show OP_PLUS = "+"
  show OP_MINUS = "-"
  show OP_AND = " ∧ "
  show OP_OR = " ∨ "
  show OP_IMPLY = " ⇒ "
  show OP_EQ = "="
  show OP_LESS = "<"
  show OP_GREATER = ">"

instance Show UOp where
  show OP_NOT = "¬" 
 
instance Show Var where
  show (VAR s) = s

instance Show FieldName where
  show (FIELD_NAME s) = s

instance Show PathCondition where
   show (P_COND []) = "True"
   show (P_COND ps) = "∧"++ show ps

instance Show Sigma where
   show (SIGMA list) = foldr f "{}" list
     where
       f (g,v) s =  s ++ " ∪ {" ++ show g++" ⇒ "++show v ++ "}"

instance Show Delta where
   show (DELTA list) = foldr f "{}" list
     where
       f (g,x,v) s = s ++ " ∪ {" ++ show g ++" ⇒ "++ show x ++"="++show v++"}" 

instance Show Formula where
   show (F_IS v) = show v
   show (F_NOT v) = "¬" ++ show v
\end{code}
\end{haskell}

\nocite{*} % Trick to include all references
\BIBLIOGRAPHY{jeeves}

\INDEX

\end{document}
