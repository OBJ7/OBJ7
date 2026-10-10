# Fixed acquisition: following a request through service delivery

**Status:** retrospective team account, written 10 October 2026. Based on my description of improvements made during 2026; not an independent performance audit.

My work at Telecel Ghana involves commercial systems and data operations. This case describes improvements made by our team to the fixed-acquisition journey. The available account supports the team’s work; it does not allocate every feature’s coding, specification, coordination, or verification to me individually.

## The journey we improved

A sales request is an early step in providing a service. Capturing the sale does not by itself tell a team whether the customer has received an installation or where a request is delayed. Our improvements addressed the route into the system, the submission process, and visibility after submission.

| Area | Change reported in the team account |
| --- | --- |
| Routes to market | A third-party acquisition feature was built and launched |
| Request submission | Scheduled batch submissions were replaced with immediate submission |
| Installation follow-up | A tracker report used the unit team’s KPIs to follow progress through installation stages |
| Sales interface | Offers and forms were organized by product, package, and price |
| Failure handling | More specific messages distinguished backend issues and missing customer information |
| Availability checks | Improvements covered service coverage, location, distribution points, and ports |

These are reported changes. I have not published the application’s internal source, screenshots, endpoints, or customer information to substantiate them publicly.

## Three lessons I draw from the work

**Follow the service beyond its first recorded event.** Installation visibility gives a team a way to follow outstanding work after the sale. A useful report needs to describe a stage in the customer journey, rather than merely count activity that is easy to record.

**An error message should help someone decide what to do next.** Missing information and a backend failure require different responses. A message that identifies the reason for failure can help a salesperson correct a request or route it appropriately. This account does not include measured correction success rates.

**A smoother interface still depends on sound validation.** Making offers easier to choose and submitting requests immediately does not remove the need to check availability. Convenience and service feasibility have to work together.

These are retrospective interpretations of the improvements. I am not presenting them as a recovered decision log or claiming that each was the original reason recorded by the team.

## How I would evaluate the result

A future evaluation could measure the time from a qualifying submitted request to its next recorded installation stage, the age of unresolved installations, and whether a user succeeds after receiving a corrective message. Each measure would need a defined population, observation window, timestamps, and treatment of cancelled requests or missing events.

No such measurements are supplied here. Immediate submission removes the scheduled submission step, but does not establish a quantified reduction in end-to-end installation time, revenue growth, or conversion.

**Contribution limit:** I contributed within the commercial systems context described above. A stronger individual case needs a verified allocation of my responsibilities for each change. Until that is available, this remains a team account. Prepared with AI assistance from my description; no newly generated code is represented as historical employer work.
