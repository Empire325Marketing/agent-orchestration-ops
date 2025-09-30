# Invoice Template

---

**INVOICE #{{invoice_id}}**

**Bill To:**
{{tenant_name}}
{{billing_address}}

**Invoice Date:** {{invoice_date}}
**Due Date:** {{due_date}}
**Billing Period:** {{period_start}} - {{period_end}}

---

## Summary

| Description | Amount |
|-------------|--------|
| Base Plan ({{tier}}) | ${{base_fee}} |
| Usage Charges | ${{usage_charges}} |
| **Subtotal** | **${{subtotal}}** |
| Credits Applied | -${{credits}} |
| **Total Due** | **${{total}}** |

---

## Usage Details

| Meter | Quantity | Rate | Amount |
|-------|----------|------|--------|
| Input Tokens | {{tokens_in_qty}} | ${{tokens_in_rate}}/1M | ${{tokens_in_amount}} |
| Output Tokens | {{tokens_out_qty}} | ${{tokens_out_rate}}/1M | ${{tokens_out_amount}} |
| Tool Calls | {{tool_calls_qty}} | ${{tool_calls_rate}}/call | ${{tool_calls_amount}} |
| Images Generated | {{images_qty}} | ${{images_rate}}/image | ${{images_amount}} |
| Egress Bandwidth | {{egress_gb}} GB | ${{egress_rate}}/GB | ${{egress_amount}} |

---

## Payment Information

**Payment Methods Accepted:**
- Credit Card (via Stripe)
- ACH Transfer
- Wire Transfer

**Remit To:**
Primarch Inc.
Account: {{bank_account}}
Routing: {{routing_number}}

**Questions?** Contact billing@primarch.ai or open a support ticket.

---

*This invoice was generated automatically. Please retain for your records.*

**Invoice ID:** {{invoice_id}}
**Generated:** {{generated_timestamp}}
