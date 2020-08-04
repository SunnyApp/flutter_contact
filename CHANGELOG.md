## 0.6.1

There shouldn't be any breaking changes, but there are significant changes to how things work under the hood  

* Contacts is duplicated as UnifiedContacts and SingleContacts, to allow access to aggregated contacts, or the raw unlinked contacts
* Parameter `withUnifyInfo` on `getContact` and `getContacts` will produce information about how contacts are linked.  It's more expensive, and therefore disabled by default on `getContacts`
* Removed any java8 dependencies
 
## 0.5.4

Merged several PRs from the community.  Thanks to:

 * MrHarcombe
 * tkeithblack
 * SamiKouati
 * worldbucks


## 0.5.2

* Added native forms, thanks to https://github.com/engylemure/ for the source

## 0.5.1

* Introduce sunny_dart dependency, updating minor version for slight changes. 

## 0.4.15

* Fixing bug with non-completing futures on Android

## 0.4.14

* Fixing bug with paging iterable that attempted to publish after the stream was closed

## 0.4.13

* Fixing contact events on ios


## 0.4.10

* Improving docs

## 0.4.9

* Getting Android up to speed

## 0.4.8

* Adding documentation
* Working on CI setup

## 0.4.7+10

* Adding sort order

## 0.4.7+9

* Fixing issue with fetching full-res images

## 0.4.7+8

* Improved performance of count
* Beefed up example screen to handle search and other features.
* Known issue: this build doesn't work for Android

## 0.4.7+7

* Move all ios operation to background as .userInitiated
* Provide convenience getter for fetching contact avatar.

## 0.4.7+6

* Fixing ios paging logic

## 0.4.7+5

* Added streaming methods for improved performance

## 0.4.7+4

* Fixing issue with copying identifier
* Also improved error handling

## 0.4.7+3

* Added removeDuplicates function to contact
* Fixed some issues with dates (specifically birthday on IOS)

## 0.4.6
 
* Fixed exports

## 0.4.5 

* Changed how dates are handled - more closely aligning to DateComponents in ios - will use a kotlin class
for Android eventually

## 0.4.4

* Initial checkin




