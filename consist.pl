:- module(consist, [
              consist/2
          ]).
/** <module> Tool for arranging train consists
 *
 */
:- use_module(library(clpfd)).

%!  consist(+Cars:list, -OrderedCars:list) is nondet
%
%   @arg Cars  a bag of cars as a list
%   @arg OrderedCars a valid ordering of the cars as a list
%
%   for simplicity the engine's assumed.
%
consist(Cars, OrderedCars) :-
    % for sanity, make sure Cars is a ground list
    % of cars
    is_list(Cars),
    ground(Cars),
    maplist(car_type, Cars),
    % we'll need the train length for many things
    length(Cars, Len),
    % create a list of the train positions
    % 1 based
    length(Order, Len),
    Order ins 1..Len,
    all_different(Order),
    % add the constraints
    constrain_positions(Cars, Order),
    % minimize distance to diner
    % we constrain Dist to be distance to diner
    diner_dist(Cars, Order, Dist),
    % label the cars
    labeling([min(Dist), ff], [Dist| Order]),
    pairs_keys_values(Pairs, Order, Cars),
    keysort(Pairs, OrderedPairs),
    pairs_keys_values(OrderedPairs, _, OrderedCars).


constrain_positions(Cars, Order) :-
    length(Cars, Len),
    % min and max car # passengers can reach
    [MinWalk, MaxWalk] ins 1..Len,
    MinWalk #=< MaxWalk,
    maplist(a_car(Len, MinWalk, MaxWalk), Cars, Order).

% the observation must be at the end, and we must
% be able to walk to it
a_car(Len, _MinWalk, Len, observation, Len).
% the baggage and RPO cars must be outside the walk area
a_car(_Len, MinWalk, MaxWalk, rpo, Order) :-
    Order #> MaxWalk #\/  Order #< MinWalk.
a_car(_Len, MinWalk, MaxWalk, baggage, Order) :-
    Order #> MaxWalk #\/  Order #< MinWalk.
% other cars must be walkable
a_car(_Len, MinWalk, MaxWalk, Car, Order) :-
    member(Car, [sleeper, chair, diner, lounge, dome]),
    Order #>= MinWalk,
    Order #=< MaxWalk.

car_type(X) :-
    member(X, [rpo, baggage, sleeper, chair, diner, lounge, dome, observation]).

diner_dist(Cars, _, 0) :-
    \+ memberchk(diner, Cars). % no diner!
diner_dist(Cars, Order, Dist) :-
    nth1(DinerIndex, Cars, diner), % diner location in Cars
    nth1(DinerIndex, Order, DinerLoc), % unbound diner location
    diner_dist(Cars, Order, DinerLoc, 0, Dist).

diner_dist([], _, _, Dist, Dist).
diner_dist([Car | T], [Order|OT], DinerLoc, SoFar, Dist) :-
    member(Car, [sleeper, chair]),
    NewSoFar #= SoFar + abs(DinerLoc - Order),
    diner_dist(T, OT, DinerLoc, NewSoFar, Dist).
% these cars don't count
diner_dist([Car | T], [_|OT], DinerLoc, SoFar, Dist) :-
    member(Car, [rpo, baggage, diner, lounge, dome, observation]),
    diner_dist(T, OT, DinerLoc, SoFar, Dist).

